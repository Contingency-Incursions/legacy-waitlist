# frozen_string_literal: true

class PilotsController < ApplicationController
  def alts
    AuthService.requires_access(@authenticated_account, "waitlist-tag:HQ-FC")

    characters = Character.joins("JOIN alt_character AS alt ON (alt.alt_id = character.id OR alt.account_id = character.id)")
                          .where("alt.alt_id = :character_id OR alt.account_id = :character_id AND id != :character_id", character_id: params[:character_id])
                          .order(name: :asc)

    render json: characters
  end

  def info
    authorize_character!(params[:character_id], "pilot-view")

    character = Character.select(:id, :name).find(params[:character_id])

    tags = []

    # Add the ACL tag to the array
    admin = Admin.select(:role).find_by(character_id: character.id)
    if admin
      keys = AuthService.get_access_keys(admin.role) # NOTE: Implement `get_access_keys` method as per your needs
      if keys.include?("waitlist-tag:HQ-FC")
        tags.append("HQ-FC")
      elsif keys.include?("waitlist-tag:TRAINEE")
        tags.append("TRAINEE")
      end
    end

    # Add specialist badges to the tags array
    badges = Badge.joins(:badge_assignments).where(badge_assignments: { characterid: character.id })
    badges.each do |badge|
      tags.push(badge.name)
    end

    active_bans = BanService.character_bans(character.id) # replace with your actual implementation logic

    render json: {
      id: character.id,
      name: character.name,
      tags: tags,
      active_bans: active_bans,
    }
  end
end
