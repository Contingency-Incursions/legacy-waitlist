module FittingService
  class FitMatch
    class << self
      def load_modules
        result = Set.new

        Rails.application.config.modules['identification'].each do |module_name|
          module_id = InvTypesService.id_of(module_name)
          unless module_id.nil?
            if VariationsData.get(module_id).present?
              VariationsData.get(module_id).each do |var|
                result.add(var[:to])
              end
            else
              result.add(module_id)
            end
          end
        end

        { rules: result.to_a }
      end

      def find_fit(fit)
        modules = Rails.cache.fetch('modules_data', expires_in: 5.days) do
          load_modules
        end
        ship_fits = FitsData.fits[fit[:hull]]
        ship_fits = ship_fits.map {|ship_fit| [ship_fit, FitsData.diff(ship_fit[:fit], fit)]}
        ship_fits.sort_by! {|fit| fit_score(fit[1], modules)}
        ship_fits[0]
      end

      private

      # ruby code
      def fit_score(diff, rules)
        score = 0

        # Missing modules: it is definitely not there
        diff[:module_missing].each do |type_id, count|
          score += 12 * count * multiplier(type_id, rules)
        end
        # Extra: does this belong here?
        diff[:module_extra].each do |type_id, count|
          score += 8 * count * multiplier(type_id, rules)
        end
        # Downgraded. Didn't have money?
        diff[:module_downgraded].each do |type_id, to|
          to.values.each do |count|
            score += 5 * count * multiplier(type_id, rules)
          end
        end
        # Upgraded? Either rich, or not actually part of our fit
        diff[:module_upgraded].each do |type_id, to|
          to.values.each do |count|
            score += count * multiplier(type_id, rules)
          end
        end

        score
      end

      def multiplier(type_id, rules)
        rules[:rules].include?(type_id) ? 100 : 1
      end
    end
  end
end
