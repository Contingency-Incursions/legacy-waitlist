# frozen_string_literal: true

class FleetService
  class << self
    def get_current_fleet_id(character_id)
      result = esi_client.get("/v1/characters/#{character_id}/fleet", character_id, ESIClientService::Fleets_ReadFleet_v1)
      result['fleet_id']
    end

    def delete_all_wings(fleet)
      current_wings = esi_client.get("/v1/fleets/#{fleet[:fleet_id]}/wings", fleet[:fleet_boss_id], ESIClientService::Fleets_ReadFleet_v1)

      current_wings.each do |wing|
        esi_client.delete("/v1/fleets/#{fleet[:fleet_id]}/wings/#{wing['id']}", fleet[:fleet_boss_id], ESIClientService::Fleets_WriteFleet_v1)
      end
    end

    def set_default_motd(esi_client, fleet, boss_system_id)
      base_motd_template = File.read("config/data/motd.dat")

      result = base_motd_template

      fc = Character.find_by(id: fleet[:fleet_boss_id])

      if fc.present?
        result = result.gsub("{fc_id}", "1379//#{fleet[:fleet_boss_id]}")
        result = result.gsub("{fc_name}", "#{fc.name}")
      end

      # Assuming TypeDB::name_of_system functionality is handled in your Ruby setup
      boss_system_name = MapSolarSystem.find(boss_system_id).solarSystemName rescue "Unknown"

      result = result.gsub("{fc_system_id}", "#{boss_system_id}")
      result = result.gsub("{fc_system_name}", "#{boss_system_name}")

      body = {
        is_free_move: false,
        motd: result
      }

      # Assuming ESI client `put`
      esi_client.put("/v1/fleets/#{fleet[:fleet_id]}", body, fleet[:fleet_boss_id], ESIClientService::Fleets_WriteFleet_v1)
    end

    def esi_client
      @esi_client ||= ESIClientService.new
    end
  end
end
