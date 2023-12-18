# frozen_string_literal: true

module Waitlist
  class ActionsController < ApplicationController
    def remove
      entry = WaitlistEntryFit.joins(:entry).where(id: params[:id]).first
      entry_id = entry.entry_id
      authorize_character!(entry[:account_id], 'waitlist-manage')
      entry.destroy
      reminaing = WaitlistEntryFit.where(entry_id: entry_id)
      if reminaing.count == 0
        WaitlistEntry.find(entry_id).destroy
      end

      Notify.send_event(['waitlist_update'], 'waitlist_update')
    end


    def empty_waitlist
      AuthService.requires_access(@authenticated_account,"waitlist-edit")
      WaitlistEntryFit.destroy_all
      WaitlistEntry.destroy_all
      Notify.send_event(%w(waitlist_update), 'waitlist_update')
    end
  end
end
