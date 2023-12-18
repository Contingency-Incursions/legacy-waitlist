# frozen_string_literal: true

class BanService


  class << self
    def bans(entity)
      entity.bans.where("revoked_at IS NULL OR revoked_at > ?", DateTime.now.to_i)
    end

    def character_bans(character_id)
      character = Character.find_by(id: character_id)
      return unless character
      bans = bans(character)
      return bans if bans.present?

      corporation_bans(character.corporation) if character.corporation
    end

    def corporation_bans(corporation)
      return unless corporation
      bans = bans(corporation)
      return bans if bans.present?

      alliance_bans(corporation.alliance) if corporation.alliance
    end

    def alliance_bans(alliance)
      return unless alliance
      bans(alliance)
    end

    def all_bans(entity)
      entity.bans.order("issued_at")
    end
  end

end
