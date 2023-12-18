# frozen_string_literal: true

class FitsData

  class << self

    def used_module_ids
      ids = []
      fits.values.flatten.each do |fit|
        ids << fit[:fit][:modules].keys
        ids << fit[:fit][:cargo].keys
      end
      ids.flatten.uniq
    end
    def fits
      @fits ||= Rails.cache.fetch('fits_data', expires_in: 5.days) do
        load_fits
      end
    end

    def diff(fit_one, fit_two)
      variations = VariationsData.instance
      modules = section_diff(fit_one[:modules], fit_two[:modules], variations)
      cargo_changer = VariationsData.drug_handling
      fit_one_cargo = fit_one[:cargo].dup.except{|k ,v| variations.cargo_ignore.include?(k)}

      cargo_changer.each do |detect, drug_change|
        if fit_one_cargo.keys.include?(detect)
          fit_one_cargo.except! {|k,v| drug_change[:remove].include?(k)}
          drug_change[:add].each do |addition, amount|
            fit_one_cargo[addition] = amount
          end
        end
      end

      cargo = section_diff(fit_one_cargo, fit_two[:cargo], variations)

      cargo_missing = cargo[:missing]

      cargo[:downgraded].each do |type_id, to|
        to.each do |_, count|
          cargo_missing[type_id] ||= 0
          cargo_missing[type_id] += count
        end
      end

      # Only count cargo as missing if it's more than 70%
      cargo_missing.select! do |type_id, count|
        expect = fit_one_cargo[type_id]

        if expect >= 10
          count > (expect * 80 / 100)
        else
          true
        end
      end

      {
        module_missing: modules[:missing],
        module_extra: modules[:extra],
        module_downgraded: modules[:downgraded],
        module_upgraded: modules[:upgraded],
        cargo_missing: cargo_missing
      }

    end

    private

    def section_diff(mods_one, mods_two, variations)
      extra = mods_two.dup
      missing = mods_one.dup
      downgraded = {}
      upgraded = {}
      missing.each do |expected_type, remaining|
        or_else = [{from: expected_type, to: expected_type, meta_diff: 0}]
        current_variations = variations.variations[expected_type] || or_else
        current_variations.each do |variation|
          next if variation[:meta_diff] == 0
          sub = [remaining, (extra[variation[:to]] || 0)].min
          if sub > 0
            missing[expected_type] -= sub
            remaining -= sub
            extra[variation[:to]] -= sub
          end
        end
      end

      missing.each do |expected_type, remaining|
        or_else = [{from: expected_type, to: expected_type, meta_diff: 0}]
        current_variations = variations.variations[expected_type] || or_else
        current_variations.each do |variation|
          sub = [remaining, (extra[variation[:to]] || 0)].min
          if sub > 0
            missing[expected_type] -= sub
            remaining -= sub
            extra[variation[:to]] -= sub

            if variation[:meta_diff] > 0
              upgraded[variation[:from]] ||= {}
              upgraded[variation[:from]][variation[:to]] ||= 0
              upgraded[variation[:from]][variation[:to]] += sub
            elsif variation[:meta_diff] < 0
              downgraded[variation[:from]] ||= {}
              downgraded[variation[:from]][variation[:to]] ||= 0
              downgraded[variation[:from]][variation[:to]] += sub
            end

          end
        end
      end

      extra = extra.select { |_k, v| v > 0 }.to_h
      missing = missing.select { |_k, v| v > 0 }.to_h

      test = 'test'

      {
        missing: missing,
        extra: extra,
        downgraded: downgraded,
        upgraded: upgraded
      }

    end

    def load_fits
      fits = {}
      fits_data = File.read("config/data/fits.dat")

      fits_data.scan(/<a href="fitting:([0-9:;_]+)" ?(hidden)?>([^<]+)<\/a>/).each do |fit|
        dna = fit[0]
        is_hidden = fit[1].present?
        fit_name = fit[2]
        parsed = FittingService::Fitting.from_dna(dna)
        if fits[parsed[:hull]].present?
          fits[parsed[:hull]] << {name: fit_name, fit: parsed, hidden: is_hidden}
        else
          fits[parsed[:hull]] = [{name: fit_name, fit: parsed, hidden: is_hidden}]
        end
      end
      fits
    end
  end

end
