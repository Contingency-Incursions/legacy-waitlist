# frozen_string_literal: true

class FleetController < ApplicationController
  def members
    character_id = params[:character_id]
    error_message = 'Fleet not found'
    # assuming an equivalent method for require_access
    AuthService.requires_access(@authenticated_account, 'fleet-view')

    begin
      fleet = Fleet.find_by_id(FleetService.get_current_fleet_id(character_id))
    rescue WithMessageError => e
      render plain: e.message, status: :bad_request and return
    end


    return render plain: error_message, status: :not_found if fleet.nil?

    in_fleet =  esi_client.get("/v1/fleets/#{fleet.id}/members", @authenticated_account.id, ESIClientService::Fleets_ReadFleet_v1)
    ship_names = InvTypesService.names_of(in_fleet.map {|f| f['ship_type_id']}.uniq)
    character_ids = in_fleet.map { |member| member['character_id'] }
    characters = Character.where(id: character_ids)

    # assuming equivalent match methods exist in Rails
    squads = FleetSquad
               .where(fleet_id: fleet.id)
               .each_with_object({}) { |squad, hash| hash[squad.squad_id] = squad.category }

    category_lookup = {}
    CategoriesData.categories.each {|c| category_lookup[c['id']] = c['name']}

    members = in_fleet.map do |member|
      wl_category = category_lookup[squads[member["squad_id"]].to_s]
      {
        id: member['character_id'],
        name: characters.find { |char| char.id == member['character_id'] }&.name,
        ship: {
          id: member['ship_type_id'], # assume mapping logic exists here
          name: ship_names[member['ship_type_id']] || 'Unknown' # assume mapping logic exists here
        },
        wl_category: wl_category
      }
    end.to_json

    render json: { members: members }, status: :ok
  end

  def info
    AuthService.requires_access(@authenticated_account, 'fleet-view')
    authorize_character!(params[:character_id], nil)
    fleet_id = FleetService.get_current_fleet_id(@authenticated_account.id)

    wings = esi_client.get("/v1/fleets/#{fleet_id}/wings", @authenticated_account.id, ESIClientService::Fleets_ReadFleet_v1)

    render json: { 'fleet_id' => fleet_id, 'wings' => wings }
  rescue => e
    render plain: e.message, status: :not_found
  end


  private
  def esi_client
    @esi_client ||= ESIClientService.new
  end
end
