# frozen_string_literal: true

class BansController < ApplicationController
  def index
    AuthService.requires_access(@authenticated_account, "bans-manage")

    # Assuming that the 'ban' table's model is named 'Ban'

    now = Time.now
    rows = Ban.joins("JOIN character as issuer ON bans.issued_by = issuer.id")
              .where("revoked_at IS NULL OR revoked_at > ?", now)
              .select("ban.id,
                       entity_id,
                       entity_name,
                       entity_type,
                       issued_at,
                       public_reason,
                       reason,
                       revoked_at,
                       issuer.id AS issued_by_id,
                       issuer.name AS issued_by_name")

    bans = rows.map do |ban|
      {
        id: ban.id,
        entity: {
          id: ban.entity_id,
          name: ban.entity_name,
          category: ban.entity_type
        },
        issued_at: ban.issued_at,
        issued_by: {
          id: ban.issued_by_id,
          name: ban.issued_by_name
        },
        reason: ban.reason,
        public_reason: ban.public_reason,
        revoked_at: ban.revoked_at,
        revoked_by: nil
      }
    end

    render json: bans
  end

  def show
    AuthService.requires_access(@authenticated_account, "bans-manage")
    entity = Character.find(params[:id])
    @bans = BanService.all_bans(entity)
    render json: @bans
  rescue => e
    render json: { error: e.message }, status: :unauthorized
  end
end
