# frozen_string_literal: true

class CommandersController < ApplicationController

  def list
    AuthService.requires_access(@authenticated_account, 'commanders-view')
    announcements = Announcement.joins(:created_by).where(revoked_at: nil)

    payload = announcements.map{|a|
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

    render status: :ok, json: payload
  end

  def public_list
    commanders = Admin.joins(:character).where(role: ['Leadership', 'FC']).order(role: :asc).map{|c| {id: c.character.id, name: c.character.name, role: c.role}}
    render status: :ok, json: commanders
  end
end
