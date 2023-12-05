# frozen_string_literal: true

# app/models/CategoryData.rb

class ImplantData
  class << self
    def get_implants(character_id)
      esi_client.get("/v2/characters/#{character_id}/implants", character_id, ESIClientService::Clones_ReadImplants_v1)
    end

    def esi_client
      @esi_client ||= ESIClientService.new
    end
  end
end
