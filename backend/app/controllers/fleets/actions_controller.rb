# frozen_string_literal: true

module Fleets
  class ActionsController < ApplicationController

    def delete_fleet
      AuthService.requires_access(@authenticated_account, 'fleet-view')
      fleet = Fleet.find(params[:fleet_id])

      fleet_members = esi_client_service.get("/v1/fleets/#{fleet.id}/members", @authenticated_account.id, ESIClientService::Fleets_ReadFleet_v1)

      fleet_members.each do |member|
        if member['character_id'] == fleet.boss_id
          next
        end

        esi_client_service.delete("/v1/fleets/#{fleet.id}/members/#{member['character_id']}/", fleet.boss_id, ESIClientService::Fleets_WriteFleet_v1)
      end

      FleetActivity.where(fleet_id: fleet.id, has_left: false).update_all(has_left: true)

      fleet.destroy

      Notify.send_event(['fleets'], 'closed')
      Notify.send_event(['fleets_updated'], 'fleet_deleted')

    end
    def invite_all
      AuthService.requires_access(@authenticated_account, 'fleet-invite')


      fleet = Fleet.find(params[:fleet_id])
      fleet_members = esi_client_service.get("/v1/fleets/#{fleet.id}/members", @authenticated_account.id, ESIClientService::Fleets_ReadFleet_v1)
      error_count = 0
      invite_count = fleet_members.size
      invited_characters = []
      fc = Character.find(fleet.boss_id)


      pilots =  WaitlistEntryFit.joins(:entry)
                                .includes(:entry)
                                .where(state: 'approved')



      pilots.each do |pilot|

        unless invited_characters.include?(pilot.character_id)
          if invite_count >= fleet.max_size
            render plain: "", status: 200
            return
          end

          squad = FleetSquad.find_by(fleet_id: fleet.id, category: pilot.category)

          if squad.nil?
            render plain: "Fleet not configured.", status: 400
            return
          end

          begin
            res = esi_client_service.post_204(
              "/v1/fleets/#{fleet.id}/members/",
              {character_id: pilot.character_id, role: 'squad_member', squad_id: squad.squad_id, wing_id: squad.wing_id},
              fleet.boss_id,
              ESIClientService::Fleets_WriteFleet_v1
            )
          rescue => e
            error_count += 1
            if error_count >= 10
              render status: :bad_request, plain: 'ESI Error cap reached, please invite manually!' and return
            end
            next
          end

          invite_count += 1
          invited_characters << pilot.character_id

          message_info = "#{fc.name} has invited your #{InvTypesService.name_of(pilot.fitting.hull)} to fleet."

          Notify.send_event(['message'], message_info, sub_override: pilot.entry.account_id.to_s)
        end
      end

      render plain: "OK", status: 200
    end

    private

    def esi_client_service
      @esi_client_service ||= ESIClientService.new
    end
  end
end
