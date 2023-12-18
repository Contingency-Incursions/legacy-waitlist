# frozen_string_literal: true

module Fleets
  class CompController < ApplicationController
    def comp
      AuthService.requires_access(@authenticated_account, 'fleet-view')

      fleet = Fleet.find(params[:fleet_id]) rescue nil

      unless fleet.present?
        render plain: 'Fleet not found', status: :not_found
      end

      in_fleet = esi_client.get("/v1/fleets/#{fleet.id}/members", @authenticated_account.id, ESIClientService::Fleets_ReadFleet_v1)

      character_ids = in_fleet.map {|m| m['character_id']}

      characters = Character.where(id: character_ids).index_by(&:id)

      badges = BadgeAssignment.where(characterid: character_ids)
                              .joins(:badge)
                              .group('characterid')
                              .pluck('characterid', "ARRAY_AGG(badge.name)")
                              .index_by(&:first)

      squads = FleetSquad.where(fleet_id: fleet.id)
                    .pluck(:squad_id, :category, :wing_id)
                    .each_with_object({}) do |(squad_id, category, wing_id), obj|
        obj[squad_id] = [category, wing_id.to_s]
      end

      on_grid_wing = squads.values.first[1]
      ship_names = InvTypesService.names_of(in_fleet.map {|f| f['ship_type_id']}.uniq)
      fleet_members = in_fleet.map do |member|
        character = characters[member['character_id']]

        {
          character: character,
          hull: { id: member['ship_type_id'], name: ship_names[member['ship_type_id']] || 'Unknown' },
          position: {
            squad: squads.fetch(member['squad_id'], [])[0] || (member['squad_id'] == -1 ? 'logi' : on_grid_wing == member['wing_id'].to_s ? 'boxer' : 'Off Grid'),
            wing: squads.key?(member['squad_id']) ? 'On Grid' : member['wing_id'] == -1 ? 'On Grid' : on_grid_wing == member['wing_id'].to_s ? 'On Grid' : 'Off Grid',
            is_alt: squads.fetch(member['squad_id'], [])[0] == 'alt',
            badges: badges.fetch(character.id, [])[1]
          }
        }
      end

      render json: fleet_members
    rescue => e
      render plain: e.message, status: :bad_request
    end

    private

    def esi_client
      @esi_client ||= ESIClientService.new
    end
  end
end
