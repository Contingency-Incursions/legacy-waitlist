# frozen_string_literal: true

module Stats
  class Processors

    class << self
      def fleet_seconds_by_character_by_month(res)
        result = Hash.new { |hash, key| hash[key] = {} }

        res.each do |row|
          result[row.yearmonth][row.character_id] = row.time_in_fleet.to_f
        end

        result
      end

      def fleet_seconds_by_hull_by_month(res)

        result = Hash.new { |hash, key| hash[key] = {} }

        res.each do |row|
          result[row.yearmonth][row.hull] = row.time_in_fleet.to_f
        end

        result
      end

      def xes_by_hull_by_month(res)

        result = Hash.new { |hash, key| hash[key] = {} }

        res.each do |row|
          result[row.yearmonth][row.hull] = row.x_count.to_f
        end

        result
      end

      def xes_by_hull_28d(res)

        result = {}

        res.each do |row|
          result[row.hull] = row.x_count.to_f
        end

        result
      end

      def fleet_seconds_by_hull_28d(res)

        result = {}

        res.each do |row|
          result[row.hull] = row.fleet_seconds.to_f
        end

        result
      end

      def fleet_seconds_by_fleet_by_day(res)

        result = Hash.new { |hash, key| hash[key] = {} }

        res.each do |row|
          result[row.date][row.fleet_id] = row.fleet_time.to_f
        end

        result
      end
    end

  end
end
