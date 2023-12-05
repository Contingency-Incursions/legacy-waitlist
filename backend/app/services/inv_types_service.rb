# frozen_string_literal: true

class InvTypesService
  PrimarySkill=182
  PrimarySkillLevel=277
  SecondarySkill=183
  SecondarySkillLevel=278
  TertiarySkill=184
  TertiarySkillLevel=279
  QuaternarySkill=1285
  QuaternarySkillLevel=1286
  QuinarySkill=1289
  QuinarySkillLevel=1287
  SenarySkill=1290
  SenarySkillLevel=1288

  EMResist=984
  ExplosiveResist=985
  KineticResist=986
  ThermalResist=987

  TrainingTimeMultiplier=275
  MetaLevel=633

  class << self

    def type_variations(ids)
      ids = ids.map{|i| i[:id]}
      mappings = {}
      true_ids = []
      id_mappings = {}
      parents = InvMetaType.where(typeID: ids).to_a
      ids.each do |type_id|
        parent_type_id_dummy = parents.find {|p| p.typeID == type_id}&.parentTypeID
        true_id = parent_type_id_dummy.present? ? parent_type_id_dummy : type_id
        true_ids << true_id
        id_mappings[true_id] = type_id
      end

      meta_mappings = InvMetaType.left_joins(:meta_attributes).includes(:meta_attributes).where(parentTypeID: true_ids).to_a

      true_ids.each do |type_id|
        metas = {type_id => 0}
        meta_items = meta_mappings.select {|m| m.parentTypeID == type_id}
        meta_items.each do |meta_item|
          meta_type_id = meta_item.typeID
          meta_level = meta_item.meta_attributes.first.valueFloat.present? ? meta_item.meta_attributes.first.valueFloat.to_i : meta_item.meta_attributes.first.valueInt
          meta_group_id = meta_item.metaGroupID
          if meta_level.present?
            metas[meta_type_id] = meta_level
          elsif meta_group_id == 1
            metas[meta_type_id] = 1
          elsif meta_group_id == 2
            metas[meta_type_id] = 2
          end
        end
        mappings[id_mappings[type_id]] = metas
      end
      mappings
    end

    def id_of(name)
      InvType.where(typeName: name).first&.typeID
    end

    def ids_of(names)
      InvType.where(typeName: names).to_a.map{|type| {name: type.typeName, id: type.typeID}}
    end

    def load_type(type_id, with_group: false)
      type = InvType
      if with_group
        type = type.joins(:inv_group).includes(:inv_group)
      end
      type.find(type_id)
    end

    def load_types(type_ids, with_skill_reqs: false, with_attributes: false, with_groups: false, with_all: false)
      types = InvType.where(typeID: type_ids.uniq)
      if with_skill_reqs
        types = types.joins(:dgm_type_attributes, :dgm_type_effects).includes(:dgm_type_attributes, :dgm_type_effects)
      elsif with_attributes
        types = types.joins(:dgm_type_attributes).includes(:dgm_type_attributes)
      elsif with_groups
        types = types.joins(:inv_group).includes(:inv_group)
      elsif with_all
        types = types.left_joins(:dgm_type_attributes, :dgm_type_effects, :inv_group).includes(:dgm_type_attributes, :dgm_type_effects, :inv_group)
      end
      result = {}
      types.each do |item_type|
        result[item_type.typeID] = item_type
      end
      type_ids.each do |type_id|
        result[type_id] = nil unless result[type_id].present?
      end
      result
    end

    def load_types_from_names(names, include_groups: false)
      query = InvType.where(typeName: names.uniq)
      if include_groups
        query = query.joins(:inv_group).includes(:inv_group)
      end
      query
    end

    def names_of(ids)
      types = load_types(ids)
      result = {}
      types.each do |k, v|
        result[k] = v.present? ? v.typeName : nil
      end
      result
    end

    def name_of(id)
      type = load_type(id)
      type.name
    end
  end
end
