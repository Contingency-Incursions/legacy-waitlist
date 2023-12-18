# frozen_string_literal: true

module Fleets
  class ConfigureController < ApplicationController

    def close_all
      AuthService.requires_access(@authenticated_account, 'fleet-admin')

      Fleet.destroy_all

      Notify.send_event(%w(fleets), 'closed_all')
      Notify.send_event(%w(fleets_updated), 'fleets_deleted')
    end

    def register
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      body = params
      authorize_character!(body[:boss_id], nil)

      begin
        fleet = esi_client.get("/v2/characters/#{body[:boss_id]}/fleet", body[:boss_id], ESIClientService::Fleets_ReadFleet_v1).with_indifferent_access
      rescue ESIError => e
        if e.status == 404
          render plain: "You are not in a fleet", status: :not_found and return
        else
          raise e
        end
      end

      fleet_id = fleet[:fleet_id]
      fleet_boss_id = fleet[:fleet_boss_id]

      members = esi_client.get("/v1/fleets/#{fleet_id}/members", fleet_boss_id, ESIClientService::Fleets_ReadFleet_v1)
      boss_system_id = nil
      members.each do |member|
        if member['character_id'] == fleet_boss_id
          boss_system_id = member['solar_system_id']
          break
        end
      end


      # Start Database transaction
      Fleet.transaction do
        FleetSquad.where(fleet_id: fleet_id).delete_all


        Fleet.upsert({
                       id: fleet_id,
                       boss_id: fleet_boss_id,
                       max_size: 40,
                       boss_system_id: boss_system_id
                     })

        if body[:default_squads]
          FleetService.delete_all_wings(fleet)

          default_squads = FleetData.load_default_squads

          default_squads.each do |wing|
            wing_name = wing[:name]
            new_wing = esi_client.post("/v1/fleets/#{fleet_id}/wings", {}, fleet_boss_id, ESIClientService::Fleets_WriteFleet_v1).with_indifferent_access

            esi_client.put("/v1/fleets/#{fleet_id}/wings/#{new_wing[:wing_id]}", { name: wing_name }, fleet_boss_id, ESIClientService::Fleets_WriteFleet_v1)

            wing[:squads].each do |squad|
              new_squad = esi_client.post("/v1/fleets/#{fleet_id}/wings/#{new_wing[:wing_id]}/squads", {}, fleet_boss_id, ESIClientService::Fleets_WriteFleet_v1).with_indifferent_access

              esi_client.put("/v1/fleets/#{fleet_id}/squads/#{new_squad[:squad_id]}", { name: squad[:name] }, fleet_boss_id, ESIClientService::Fleets_WriteFleet_v1)

              FleetSquad.create(fleet_id: fleet_id, category: squad[:map_to], wing_id: new_wing[:wing_id], squad_id: new_squad[:squad_id]) if squad[:map_to].present?

            end

          end
        else
          body[:squads].each do |squad|
            FleetSquad.create(fleet_id: fleet_id, category: squad[:category], wing_id: squad[:wing_id], squad_id: squad[:id])
          end
        end
      end

      if body[:default_motd]
        FleetService.set_default_motd(esi_client, fleet, boss_system_id)
      end

      Notify.send_event(%w(fleets), 'registered')
      Notify.send_event(%w(fleets_updated), 'fleet_registered')

      render plain: "/fc/fleets/#{fleet_id}"
    end

    def index
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      fleets_data = Fleet.select('
      fleet.id,
      fleet.boss_system_id,
      fleet.visible,
      character.id as boss_id,
      character.name as boss_name,
      fleet.max_size,
      fleet.error_count,
      COUNT(DISTINCT fleet_activity.character_id) as size
    ')
                         .joins('LEFT JOIN character ON character.id = fleet.boss_id')
                         .joins('LEFT JOIN fleet_activity ON fleet_activity.fleet_id = fleet.id AND fleet_activity.has_left = false')
                         .group('fleet.id, character.id').map do |fleet|

        boss = Character.new(id: fleet.boss_id, name: fleet.boss_name)

        # Replace name_of_system as per your application
        boss_system_name = MapSolarSystem.find(fleet.boss_system_id).solarSystemName rescue "Unknown"

        {
          id: fleet.id,
          boss: boss,
          boss_system: {
            id: fleet.boss_system_id,
            name: boss_system_name
          },
          is_listed: fleet.visible,
          size: fleet.size || 0,
          size_max: fleet.max_size,
          error_count: fleet.error_count
        }
      end

      render json: fleets_data.as_json
    end

    private

    def esi_client
      @esi_client ||= ESIClientService.new
    end
  end
end
