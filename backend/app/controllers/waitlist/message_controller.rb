# frozen_string_literal: true

module Waitlist
  class MessageController < ApplicationController
    def send_message
      AuthService.requires_access(@authenticated_account, 'waitlist-manage')
      # Assume Application model with associated WaitlistEntryFit and Character models
      # Also assume that get_db is equivalent to active record queries in Ruby on Rails
      entry = WaitlistEntryFit.joins(:entry)
                              .includes(:entry)
                              .where(id: params[:id])
                              .first

      entry&.update(review_comment: params[:message])

      user = Character.find_by(id: @authenticated_account.id)

      Notify.send_event(%w(waitlist_update), 'waitlist_update')

      message_info = {
        message: params[:message].to_s,
        title: format('%s has sent you a message.', user.name)
      }

      Notify.send_event(['message'], message_info, sub_override: entry&.entry.account_id.to_s)

      render plain: 'OK', status: 200
    end

    def reject
      AuthService.requires_access(@authenticated_account, 'waitlist-manage')

      entry = WaitlistEntryFit.joins(:entry)
                              .includes(:entry)
                              .find(params[:id])

      entry.update(review_comment: params[:review_comment], state: 'rejected')

      fit = entry.fitting

      Notify.send_event(%w(waitlist_update), 'waitlist_update')

      message_info = {
        message: params[:review_comment].to_s,
        title: "Fit Rejected: #{InvTypesService.name_of(fit.hull)}"
      }

      Notify.send_event(['message'], message_info, sub_override: entry.entry.account_id.to_s)

      render plain: 'OK', status: 200
    end

    def approve
      AuthService.requires_access(@authenticated_account, 'waitlist-manage')

      WaitlistEntryFit.where(id: params[:id]).update(state: 'approved')

      Notify.send_event(%w(waitlist_update), 'waitlist_update')

      render plain: 'OK', status: 200
    end
  end
end
