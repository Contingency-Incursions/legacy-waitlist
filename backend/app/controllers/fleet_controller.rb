# frozen_string_literal: true

class FleetController < ApplicationController

  def members
    character_id = params[:character_id]
    error_message = 'Fleet not found'
    # assuming an equivalent method for require_access
    AuthService.requires_access(@authenticated_account, 'fleet-view')

    @fleet = Fleet.find_by_id(FleetService.new.get_current_fleet_id(character_id))

    return render json: { error: error_message }, status: :not_found if @fleet.nil?

    in_fleet = @fleet.fleet_members.where(character_id: character_id)
    character_ids = in_fleet.map { |member| member.character_id }
    characters = Character.where(id: character_ids)

    # assuming equivalent match methods exist in Rails
    squads = FleetSquad
               .where(fleet_id: @fleet.id)
               .each_with_object({}) { |squad, hash| hash[squad.squad_id] = squad.category }

    # assuming equivalent match methods exist in Rails
    category_lookup = Category
                        .categories
                        .each_with_object({}) { |category, hash| hash[category.id] = category.name }

    members = in_fleet.map do |member|
      wl_category = squads[member.squad_id].and_then { |s| category_lookup[s] }.and_then { |s| s.to_s }
      {
        id: member.character_id,
        name: characters.find { |char| char.id == member.character_id }&.name,
        ship: {
          id: member.ship_type_id, # assume mapping logic exists here
          name: type_db.name_of(member.ship_type_id) # assume mapping logic exists here
        },
        wl_category: wl_category
      }
    end.to_json

    render json: { members: members }, status: :ok
  end

  private

  def authenticate_user
    unless current_user
      render json: { error: 'You need to be logged in to access this resource' }, status: :unauthorized
    end
  end

  def authorize_character!(action)
    # An equivalent method for `authorize_character` can handle the character authorization here.
    render json: { error: 'Unauthorized action' }, status: :unauthorized unless current_user.has_access?(action)
  end   #replace with your authorization mechanism
end
