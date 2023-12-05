# frozen_string_literal: true

class History::ActivityController < ApplicationController
  def fleet_history
    # assuming authorize_character! sets @character if authorized
    authorize_character!(params[:character_id], "fleet-activity-view")

    activity = FleetActivity.where(character_id: params[:character_id])
                            .order(first_seen: :desc)
                            .pluck(:hull, :first_seen, :last_seen)

    time_by_hull = Hash.new(0)
    entries = []

    activity.each do |hull, first_seen, last_seen|
      time_in_fleet = last_seen - first_seen
      time_by_hull[hull] += time_in_fleet

      entries << {
        hull: {
          id: hull,
        },
        logged_at: first_seen,
        time_in_fleet: time_in_fleet
      }
    end

    # get the names for each hull from InvTypeService
    hull_names = InvTypesService.names_of(time_by_hull.keys)

    # replace hull ids with their names in entries
    entries.map! do |entry|
      entry[:hull][:name] = hull_names[entry[:hull][:id]]
      entry
    end

    summary = time_by_hull.map do |hull, time_in_fleet|
      {
        hull: {
          id: hull,
          name: hull_names[hull]
        },
        time_in_fleet: time_in_fleet
      }
    end.sort_by { |h| -h[:time_in_fleet] }

    render json: {
      activity: entries,
      summary: summary
    }
  end
end
