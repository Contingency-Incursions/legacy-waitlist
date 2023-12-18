# frozen_string_literal: true

module Waitlist
  class InviteController < ApplicationController

    def invite
      AuthService.requires_access(@authenticated_account,"fleet-invite")

      wef = WaitlistEntryFit.find(params[:id])
      we = wef.entry
      fit = wef.fitting
      acl = Admin.where(character_id: we.account_id).exists?

      select_cat = wef.is_alt ? 'alt' : wef.category

      fleet_squad = FleetSquad.joins(:fleet)
                         .find_by(fleet: {boss_id: params[:character_id]}, category: select_cat)
      if fleet_squad.nil?
        return render plain: "Fleet not configured", status: 400
      end

      # Prevent a trainee from inviting a Training Nestor or Retired Logi to fleet

      if fit.hull == 'Nestor' && !acl
        AuthService.requires_access(@authenticated_account,"waitlist-tag:HQ-FC")
        if Badge.joins(:badge_assignments)
                .where(name: 'LOGI', 'badge_assignments.character_id': wef.character_id)
                .count == 0
          return render plain: "You are not allowed to invite a training Nestor to fleet.", status: 400
        end
      end

      # ESI_Client
      esi_client_service ||= ESIClientService.new

      esi_client_service.post_204(
        "/v1/fleets/#{fleet_squad.fleet_id}/members/",
        {
          character_id: wef.character_id,
          role: 'squad_member',
          squad_id: fleet_squad.squad_id,
          wing_id: fleet_squad.wing_id
        },
        params[:character_id],
        ESIClientService::Fleets_WriteFleet_v1
      )

      fc = Character.find(@authenticated_account.id)

      Notify.send_event(%w(waitlist_update), 'waitlist_update')

      message_info = "#{fc.name} has invited your #{InvTypesService.name_of(fit.hull)} to fleet."

      Notify.send_event(['message'], message_info, sub_override: wef.entry.account_id.to_s)

      render plain: "OK", status: 200
    end
  end
end
