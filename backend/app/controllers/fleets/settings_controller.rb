# frozen_string_literal: true

module Fleets
  class SettingsController < ApplicationController

    def get_fleet
      AuthService.requires_access(@authenticated_account, 'fleet-view')

      fleet = Fleet.joins("JOIN character as fc ON fc.id=fleet.boss_id LEFT JOIN fleet_activity as fa ON fa.fleet_id=fleet.id and fa.has_left = false")
                   .select("fleet.id, fleet.boss_system_id, fleet.visible as visible, fc.id as boss_id, fc.name as boss_name, fleet.max_size, fleet.error_count, COUNT(DISTINCT fa.character_id) as size")
                   .group("fleet.id, fc.id")
                   .where("fleet.id = ?", params[:fleet_id])
                   .first

      if fleet.present?
        boss_name = Character.select(:name).find_by(id: fleet.boss_id).name
        boss_system = MapSolarSystem.select(:solarSystemName).find(fleet.boss_system_id).solarSystemName rescue nil

        fleet_settings = {
          boss: {
            id: fleet.boss_id,
            name: boss_name,
            corporation_id: nil
          },
          boss_system: {
            id: fleet.boss_system_id,
            name: boss_system || "Unknown System"
          },
          size: fleet.size,
          size_max: fleet.max_size,
          visible: fleet.visible,
          error_count: fleet.error_count
        }

        render json: fleet_settings

      else
        render plain: "Fleet not found.", status: :not_found
      end
    end

    def update_boss
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      fleet_id = params[:fleet_id]

      fleet = Fleet.find(fleet_id)

      if fleet
        fleet.update(boss_id: params[:fleet_boss], error_count: 0)
      end

      Notify.send_event(%w(fleet_settings), {id: fleet_id, key: 'fleet_settings'})

      render plain: 'Ok', status: 200
    end

    def update_visibility
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      fleet_id = params[:fleet_id]

      fleet = Fleet.find(fleet_id)

      if fleet
        fleet.update_attribute(:visible, params[:visible])
      end

      Notify.send_event(%w(fleet_settings), {id: fleet_id.to_i, key: 'fleet_settings'})
      Notify.send_event(%w(visibility), '""')

      render plain: 'Ok', status: 200
    end

    def update_size
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      fleet_id = params[:fleet_id]

      fleet = Fleet.find(fleet_id)

      if fleet
        fleet.update_attribute(:max_size, params[:max_size])
      end

      Notify.send_event(%w(fleet_settings), {id: fleet_id.to_i, key: 'fleet_settings'})

      render plain: 'Ok', status: 200
    end

  end
end
