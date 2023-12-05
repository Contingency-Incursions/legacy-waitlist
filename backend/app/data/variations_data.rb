# frozen_string_literal: true

class VariationsData

  attr_accessor :variations, :cargo_ignore, :file

  class << self
    def instance
      Rails.cache.fetch('variations_data', expires_in: 5.days) do
        VariationsData.new
      end
    end

    def get(from)
      instance.variations[from]
    end

    def drug_handling
      data = Rails.configuration.modules['drugs_approve_override']
      names_to_id = data.map {|d| d['detect']}
      names_to_id += data.map {|d| d['remove']}.flatten
      names_to_id += data.map {|d| d['add'].map{|e| e['name']}}.flatten
      ids = InvTypesService.ids_of(names_to_id.uniq)
      drug_map = {}
      data.each do |item_type|
        remove = []
        add = {}
        item_type['remove'].each do |entry|
          remove << ids.find{|i| i[:name] == entry}[:id]
        end

        item_type['add'].each do |entry|
          add[ids.find{|i| i[:name] == entry['name']}] = entry['amount']
        end
        drug_map[ids.find{|i| i[:name] == item_type['detect']}] = {
          add: add,
          remove: remove
        }

      end

      drug_map
    end

  end

  def initialize
    @file = Rails.configuration.modules
    @variations = {}
    @cargo_ignore = []
    add_alternatives
    add_meta
    add_t1
    add_by_attribute
    add_cargo_ignore
  end

  private

  def add_cargo_ignore
    @cargo_ignore += InvTypesService.ids_of(@file['cargo_ignore']).map {|a| a[:id]}
  end

  def add_by_attribute
    to_merge = []
    base_ids = InvTypesService.ids_of(@file['from_attribute'].map { |k| k['base'] }.flatten.uniq)
    base_variations = InvTypesService.type_variations(base_ids)
    @file['from_attribute'].each do |entry|
      attribute = entry['attribute']
      module_ids = []
      entry['base'].each do |base_mod|
        base_id = base_ids.find { |type| type[:name] == base_mod }[:id]
        base_variations[base_id].each do |id, meta|
          module_ids << id
        end
      end

      mods_with_attributes = InvTypesService.load_types(module_ids, with_attributes: true).map { |id, type| [id, type.cached_attributes.find { |a| a.attributeID == attribute }.valueFloat] }

      mods_with_attributes.sort_by { |a| a[1] }
      mods_with_attributes.reverse! if entry['reverse']

      tiers = {}
      tier_i = 1
      last_value = mods_with_attributes[0][1]
      mods_with_attributes.each do |id, value|
        if (last_value - value).abs > 0.0000000001
          tier_i += 1
          last_value = value
        end

        tiers[id] = tier_i
      end
      to_merge << tiers
    end

  to_merge.each do |merge|
    merge_tiers(merge)
  end
end

def add_t1
  to_merge = []
  names_to_map = @file['accept_t1']
  names_to_map += @file['accept_t1'].map { |e| e[0..-2] }
  ids = InvTypesService.ids_of(names_to_map)
  @file['accept_t1'].each do |entry|
    t2_id = ids.find { |n| n[:name] == entry }[:id]
    t1_id = ids.find { |n| n[:name] == entry[0..-1] }[:id]
    tiers = {
      t2_id => 2,
      t1_id => 1
    }
    to_merge << tiers
  end
  to_merge.each do |merge|
    merge_tiers(merge)
  end
end

def add_meta
  to_merge = []
  base_ids = InvTypesService.ids_of(@file['from_meta'].map { |k| k['base'] })
  base_variations = InvTypesService.type_variations(base_ids)
  abyssal_ids = InvTypesService.ids_of(@file['from_meta'].map { |k| k['abyssal'] }.compact)
  alternative_ids = InvTypesService.ids_of(@file['from_meta'].map { |k| k['alternative'] }.compact)
  @file['from_meta'].each do |entry|
    base_id = base_ids.find { |type| type[:name] == entry['base'] }[:id]
    entry_variations = base_variations[base_id]
    if entry['abyssal']
      entry_variations[abyssal_ids.find { |t| t[:name] == entry['abyssal'] }[:id]] = entry_variations[base_id]
    end
    if entry['alternative']
      entry_variations[alternative_ids.find { |t| t[:name] == entry['alternative'] }[:id]] = entry_variations[base_id]
    end
    to_merge << entry_variations
  end

  to_merge.each do |merge|
    merge_tiers(merge)
  end

end

def add_alternatives
  to_merge = []
  names_to_ids = InvTypesService.ids_of(@file['alternatives'].flatten.uniq)
  @file['alternatives'].each do |group|
    tiers = {}
    tier_i = 0
    group.each do |tier|
      tier_i += 1
      tier.each do |mod|
        tiers[names_to_ids.find { |n| n[:name] == mod }[:id]] = tier_i
      end
    end
    to_merge << tiers
  end
  to_merge.each do |merge|
    merge_tiers(merge)
  end
end

def merge_tiers(tiers)
  tiers.each do |module_i, tier_i|
    if @variations.key?(module_i)
      raise "Duplicate declaration for ID #{module_i}"
    end

    vars = []

    tiers.each do |module_j, tier_j|
      vars << {
        from: module_i,
        to: module_j,
        meta_diff: tier_j - tier_i
      }
    end

    vars.sort_by! do |v|
      v[:meta_diff] < 0 ? 1_000_000 - v[:meta_diff] : v[:meta_diff]
    end

    @variations[module_i] = vars
  end
end

end
