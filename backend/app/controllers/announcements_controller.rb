# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  before_action :authenticate!, except: [:list]
  def list
    payload = get_active_announcements

    render status: :ok, json: payload
  end

  def create
    AuthService.requires_access(@authenticated_account, 'waitlist-tag:HQ-FC')
    account_id = @authenticated_account.id # Replace with a method that retrieves the authenticated account's id

    announcement = Announcement.new(
      message: params[:message],
      is_alert: params[:is_alert],
      pages: params[:pages],
      created_by_id:  account_id,
      created_at: Time.now
    )

    payload = get_active_announcements



    if announcement.save
      # If you want to send this new announcement to some service, you should do this here
      # Since it was not directly related to the conversion of your Rust function into Rails, I omitted it here
      Notify.send_event(%w(announcment;new), payload)
      render plain: 'Ok', status: :ok
    else
      render json: { errors: announcement.errors.full_messages }, status: :bad_request
    end

  end

  def update
    AuthService.requires_access(@authenticated_account, 'waitlist-tag:HQ-FC')
    announcement_id = params[:id] # <announcement_id> in path will be named "id" by default by Rails.
    account_id = @authenticated_account.id

    # Fetch the announcement. If the announcement is not found or was revoked, it will return nil.
    announcement = Announcement.where(id: announcement_id, revoked_at: nil).first

    if announcement.nil?
      render plain: 'Announcement could not be found.', status: :bad_request
    else
      if announcement.update(
        message: params[:message],
        is_alert: params[:is_alert],
        pages: params[:pages],
        created_by_id: account_id
      )
        payload = get_active_announcements
        Notify.send_event(%w(announcment;updated), payload)
        # If you want to send this new announcement to some service, you should do it here
        # Since it did not seem directly related to the question, I omitted it here
        render json: { message: 'Ok' }, status: :ok
      else
        render json: { errors: announcement.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      AuthService.requires_access(@authenticated_account, 'waitlist-tag:HQ-FC')
      announcement_id = params[:id] # <announcement_id> in path will be named "id" by default by Rails.
      account_id = @authenticated_account.id

      # Fetch the announcement. If the announcement is not found or was revoked, it will return nil.
      announcement = Announcement.where(id: announcement_id, revoked_at: nil).first

      if announcement.nil?
        render plain: 'Announcement could not be found or has already been deleted.', status: :bad_request
      else
        if announcement.update(
          revoked_by_id: account_id,
          revoked_at: DateTime.now
        )
          payload = get_active_announcements
          Notify.send_event(%w(announcment;updated), payload)
          # If you want to send this new announcement to some service, you should do this here
          # Since it did not seem directly related to the question, I omitted it here
          render plain: 'Ok', status: :ok
        else
          render plain: "Failed to delete the announcement. #{announcement.errors.full_messages.join(', ')}", status: :internal_server_error
        end
      end
    end
  end

  private

  def get_active_announcements
    announcements = Announcement.joins(:created_by).where(revoked_at: nil)
    announcements.map{|a|
      {
        id: a.id,
        message: a.message,
        is_alert: a.is_alert,
        pages: a.pages,
        created_by: {
          id: a.created_by.id,
          name: a.created_by.name,
          corporation_id: nil
        },
        created_at: a.created_at,
        revoked_by: nil,
        revoked_at: nil
      }
    }
  end
end
