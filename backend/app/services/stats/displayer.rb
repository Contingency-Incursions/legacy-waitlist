# frozen_string_literal: true

module Stats
  class Displayer
    class << self
      def build_fleet_seconds_by_hull_by_month(source)
        begin
          translated_source = translate_hulls_2d(source)
          filter_into_other_2d(translated_source, 0.01)
        rescue => e
          raise "Error: #{e.message}"
        end
      end

      def build_fleet_seconds_by_fleet_by_day(source)
        source.transform_values { |values| values.values.sum }
      end

      def build_xes_by_hull_by_month(source)
        begin
          translated_source = translate_hulls_2d(source)
          filter_into_other_2d(translated_source, 0.01)
        rescue => e
          raise "Error: #{e.message}"
        end
      end

      def build_fleet_seconds_by_month(source)
        source.transform_values { |values| values.values.sum }
      end

      def build_pilots_by_month(source)
        source.transform_values { |values| values.size.to_f }
      end

      def build_xes_by_hull_28d(source)
        begin
          translated_source = translate_hulls_1d(source)
          filter_into_other_1d(translated_source, 0.01)
        rescue => e
          raise "Error: #{e.message}"
        end
      end

      def build_fleet_seconds_by_hull_28d(source)
        begin
          translated_source = translate_hulls_1d(source)
          filter_into_other_1d(translated_source, 0.01)
        rescue => e
          raise "Error: #{e.message}"
        end
      end

      def build_x_vs_time_by_hull_28d(source_x, source_time)
        sum_x = source_x.values.sum
        sum_time = source_time.values.sum
        begin
          translated_x = filter_into_other_1d(translate_hulls_1d(source_x), 0.01)
          translated_time = translate_hulls_1d(source_time)
        rescue => e
          raise "Error: #{e.message}"
        end

        result = {}
        translated_x.each do |hull, x_count|
          result[hull] = { "X" => x_count / sum_x, "Time" => 0.0 }
        end

        translated_time.each do |hull, time|
          entry = result[hull] || result["Other"]
          entry["Time"] += time / sum_time
        end

        result
      end

      def build_time_spent_in_fleet_by_month(source)
        result = {}

        source.each do |month, pilots|
          this_month = Hash.new(0)
          pilots.values.each do |time_in_fleet|
            bucket = case time_in_fleet
                     when 0..(3600.0)
                       "a. <1h"
                     when (3600.0)..(5.0*3600.0)
                       "b. 1-5h"
                     when (5.0*3600.0)..(15.0*3600.0)
                       "c. 5-15h"
                     when (15.0*3600.0)..(40.0*3600.0)
                       "d. 15-40h"
                     else
                       "e. 40h+"
                     end
            this_month[bucket] += 1.0
          end
          result[month] = this_month
        end

        result
      end
      def translate_hulls_2d(source)
        result = {}

        source.each do |k, value|
          begin
            result[k] = translate_hulls_1d(value)
          rescue TypeError => e
            return e
          end
        end

        result
      end

      def translate_hulls_1d(source)
        ids = source.keys

        begin
          types = InvTypesService.load_types(ids)
        rescue => e
          return e
        end

        result = {}
        source.each do |t, value|
          the_type = types[t]

          if the_type
            result[the_type.name] = value
          else
            raise "TypeError: NothingMatched"
          end
        end

        result
      end

      def filter_into_other_2d(source, threshold)
        sums = Hash.new(0)
        total = 0.0

        source.each_value do |series|
          series.each do |name, value|
            sums[name] += value
            total += value
          end
        end

        result = {}
        source.each do |top_level_key, series|
          other = 0.0
          these = {}

          series.each do |name, value|
            fraction = sums[name] / total
            if fraction > threshold
              these[name] = value
            else
              other += value
            end
          end

          these["Other"] = other
          result[top_level_key] = these
        end

        result
      end

      def filter_into_other_1d(source, threshold)
        sum = source.values.sum

        other = 0.0
        result = {}

        source.each do |name, value|
          if value / sum > threshold
            result[name] = value
          else
            other += value
          end
        end

        result["Other"] = other

        result
      end
    end
  end
end
