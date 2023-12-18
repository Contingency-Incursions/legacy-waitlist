# frozen_string_literal: true

module Stats
  class Queries
    class << self
      def fleet_seconds_by_character_by_month
        FleetActivity.select("TO_CHAR(to_timestamp(first_seen), 'YYYY/MM') AS yearmonth, character_id, CAST(SUM(last_seen- first_seen) AS BIGINT) as time_in_fleet")
                           .group('yearmonth', :character_id).load_async
      end

      def fleet_seconds_by_hull_by_month
        FleetActivity.select("TO_CHAR(to_timestamp(first_seen), 'YYYY/MM') AS yearmonth, CAST(hull AS BIGINT), CAST(SUM(last_seen - first_seen) AS BIGINT) as time_in_fleet")
                     .group('yearmonth', :hull).load_async
      end

      def xes_by_hull_by_month
        FitHistory.joins(:fitting)
                  .select("TO_CHAR(to_timestamp(logged_at), 'YYYY/MM') AS yearmonth, CAST(hull AS BIGINT), COUNT(DISTINCT character_id) as x_count")
                  .group('yearmonth', :hull).load_async
      end

      def xes_by_hull_28d
        ago_28d = 28.days.ago.to_i

        FitHistory.joins(:fitting)
                  .select("CAST(hull AS BIGINT), COUNT(DISTINCT character_id) as x_count")
                  .where('logged_at > ?', ago_28d)
                  .group(:hull).load_async
      end

      def fleet_seconds_by_hull_28d
        ago_28d = 28.days.ago.to_i

        FleetActivity.select("CAST(hull AS BIGINT), CAST(SUM(last_seen - first_seen) AS BIGINT) as fleet_seconds")
                     .where('first_seen > ?', ago_28d)
                     .group(:hull).load_async
      end

      def fleet_seconds_by_fleet_by_day
        FleetActivity.select("TO_CHAR(to_timestamp(first_seen), 'YYYY-MM-DD') AS date, fleet_id, CAST((MAX(last_seen) - MIN(first_seen)) AS BIGINT) as fleet_time")
                     .group(:date, :fleet_id)
                     .order(:date).load_async
      end
    end
  end
end
