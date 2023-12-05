# frozen_string_literal: true

class FleetService
  def get_current_fleet_id(character_id)
    begin
      result = esi_client.get("/v1/characters/#{character_id}/fleet", character_id, ESIClientService::Fleets_ReadFleet_v1)
      return result['fleet_id']
    rescue ESIError::StatusIs400
      return 'You are not in a fleet'
    rescue => e
      return e.message
    end
  end

  def esi_client
    @esi_client ||= ESIClientService.new
  end
end
