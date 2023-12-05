# frozen_string_literal: true

class AffiliationService
  def update_character_affiliation(id)
    response = esi_client.get_unauthenticated("/latest/characters/#{id}")
    character = JSON.parse(response.body)

    update_corp_affiliation(character['corporation_id'])

    active_record_character = Character.find_by(id: id)

    if active_record_character.nil?
      Character.create(id: id, name: character['name'], corporation_id: character['corporation_id'])
    else
      active_record_character.update(name: character['name'], corporation_id: character['corporation_id'])
    end
  end

  def update_corp_affiliation(id)
    corporation = Corporation.find_by(id: id)

    if corporation && (corporation.updated_at - 24.hours < Time.now.utc.to_i)
      return
    end

    response = esi_client.get_unauthenticated("/latest/corporations/#{id}")
    esi_corporation = JSON.parse(response.body)

    if esi_corporation['alliance_id']
      update_alliance(esi_corporation['alliance_id'])
    end

    if corporation.nil?
      Corporation.create(id: id, name: esi_corporation['name'], alliance_id: esi_corporation['alliance_id'], updated_at: Time.now.utc.to_i)
    else
      corporation.update(name: esi_corporation['name'], alliance_id: esi_corporation['alliance_id'], updated_at: Time.now.utc.to_i)
    end
  end

  def update_alliance(id)
    response = esi_client.get_unauthenticated("/latest/alliances/#{id}")
    esi_alliance = JSON.parse(response.body)
    alliance = Alliance.find_by(id: id)

    if alliance.nil?
      Alliance.create(id: id, name: esi_alliance['name'])
    else
      alliance.update(name: esi_alliance['name'])
    end
  end

  private

  def esi_client
    @esi_client ||= ESIClientService.new
  end
end
