# frozen_string_literal: true

# app/models/CategoryData.rb

class CategoriesData
  class << self
    delegate :categories, :rules, to: :category_data

    def categorize(fit)
      category_data.rules.find do |(type_id, _)|
        fit[:hull] == type_id || fit[:modules].key?(type_id)
      end&.last
    end

    private

    def category_data
      @category_data ||= build_category_data
    end

    def build_category_data
      Struct.new(:categories, :rules)
            .new(Rails.configuration.categories['categories'], build_rules)
    end

    def build_rules
      rules = []
      Rails.configuration.categories['rules'].each do |category|
        rules << [InvTypesService.id_of(category['item']), category['category']]
      end
      rules
    end
  end
end
