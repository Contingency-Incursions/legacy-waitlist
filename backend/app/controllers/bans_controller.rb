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

  def list
    begin
      AuthService.requires_access(@authenticated_account, "bans-manage")

      now = Time.now

      bans = Ban.joins(:issued_by)
                .select("ban.id, entity_id, entity_name, entity_type, issued_at, public_reason, reason, revoked_at, character.id AS issued_by_id, character.name AS issued_by_name")
                .where('revoked_at IS NULL OR revoked_at > ?', now.to_i)

      render json: bans.map {|ban|
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
            name: ban.issued_by_name,
            corporation_id: nil
          },
          reason: ban.reason,
          public_reason: ban.public_reason,
          revoked_at: ban.revoked_at,
          revoked_by: nil
        }
      }
    rescue => e
      render plain: e.message, status: :bad_request
    end
  end

  def create
    AuthService.requires_access(@authenticated_account, "bans-manage")

    if params[:entity].blank?
      return render plain: "One or more body parameters are missing: [\"id\", \"name\", \"kind\"]", status: :bad_request
    end

    now = Time.current

    url = "/latest/#{params[:entity][:category].downcase.pluralize}/#{params[:entity][:id]}"
    esi_response = esi_client.get_unauthenticated(url) # Use the HTTP client of your choice

    admin = Admin.find_by(character_id: params[:entity][:id])
    if admin.present?
      return render plain: "#{admin.role} accounts cannot be banned.", status: :bad_request
    end

    if params[:revoked_at].presence
      expires_at = params[:revoked_at] + 11.hours
    else
      expires_at = nil
    end

    Ban.create!(
      entity_type: params[:entity][:category],
      entity_id: params[:entity][:id],
      entity_name: esi_response.as_json['name'],
      issued_at: now,
      issued_by: Character.find(@authenticated_account.id),
      reason: params[:reason],
      public_reason: params[:public_reason],
      revoked_at: expires_at,
      )

    render plain: 'OK'
  end

  private

  def esi_client
    @esi_client ||= ESIClientService.new
  end

end
