# frozen_string_literal: true

class StatisticsController < ApplicationController
  def statistics
    AuthService.requires_access(@authenticated_account, "stats-view")

    seconds_by_character_month_data = Stats::Queries.fleet_seconds_by_character_by_month
    seconds_by_hull_month_data = Stats::Queries.fleet_seconds_by_hull_by_month
    xes_by_hull_month_data = Stats::Queries.xes_by_hull_by_month
    xes_by_hull_28d_data = Stats::Queries.xes_by_hull_28d
    seconds_by_hull_28d_data = Stats::Queries.fleet_seconds_by_hull_28d
    seconds_by_fleet_by_day_data = Stats::Queries.fleet_seconds_by_fleet_by_day

    seconds_by_character_month = Stats::Processors.fleet_seconds_by_character_by_month(seconds_by_character_month_data)
    seconds_by_hull_month = Stats::Processors.fleet_seconds_by_hull_by_month(seconds_by_hull_month_data)
    xes_by_hull_month = Stats::Processors.xes_by_hull_by_month(xes_by_hull_month_data)
    xes_by_hull_28d = Stats::Processors.xes_by_hull_28d(xes_by_hull_28d_data)
    seconds_by_hull_28d = Stats::Processors.fleet_seconds_by_hull_28d(seconds_by_hull_28d_data)
    seconds_by_fleet_by_day = Stats::Processors.fleet_seconds_by_fleet_by_day(seconds_by_fleet_by_day_data)

    statistics_response = {
      fleet_seconds_by_hull_by_month: Stats::Displayer.build_fleet_seconds_by_hull_by_month(seconds_by_hull_month),
      fleet_seconds_by_fleet_by_day: Stats::Displayer.build_fleet_seconds_by_fleet_by_day(seconds_by_fleet_by_day),
      xes_by_hull_by_month: Stats::Displayer.build_xes_by_hull_by_month(xes_by_hull_month),
      fleet_seconds_by_month: Stats::Displayer.build_fleet_seconds_by_month(seconds_by_hull_month),
      pilots_by_month: Stats::Displayer.build_pilots_by_month(seconds_by_character_month),
      xes_by_hull_28d: Stats::Displayer.build_xes_by_hull_28d(xes_by_hull_28d),
      fleet_seconds_by_hull_28d: Stats::Displayer.build_fleet_seconds_by_hull_28d(seconds_by_hull_28d),
      x_vs_time_by_hull_28d: Stats::Displayer.build_x_vs_time_by_hull_28d(xes_by_hull_28d, seconds_by_hull_28d),
      time_spent_in_fleet_by_month: Stats::Displayer.build_time_spent_in_fleet_by_month(seconds_by_character_month)
    }

    render json: statistics_response, status: :ok
  end
end
