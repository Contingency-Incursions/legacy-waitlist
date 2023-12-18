# frozen_string_literal: true

module Fleets
  class HistoricController < ApplicationController

    def history
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      fleets = FleetActivity.select("
            fleet_id,
            character.name as character_name,
            MAX(fleet_activity.last_seen) AS fleet_end,
            CAST((MAX(fleet_activity.last_seen) - MIN(fleet_activity.first_seen)) AS BIGINT) AS fleet_time
        ")
                    .joins("LEFT JOIN character ON character.id = fleet_activity.character_id")
                    .where(is_boss: true)
                    .group(:fleet_id, 'character.name')
                    .order('fleet_end DESC')
                    .limit(20)

      render json: { 'fleets' => fleets.map(&:attributes) }
    end

  end
end
