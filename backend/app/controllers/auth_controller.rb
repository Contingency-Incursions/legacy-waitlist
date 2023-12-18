# frozen_string_literal: true

class AuthController < ApplicationController
  include AuthService
  before_action :authenticate!, only: [:set_wiki_passwd, :logout, :whoami]

  # assuming you have a before_action that sets @current_account if any

  def set_wiki_passwd
    AuthService.requires_one_of_access(@authenticated_account, "waitlist-tag:TRAINEE,wiki-editor")

    character = Character.find(@authenticated_account.id)
    wiki_user = character.name.gsub(/[' ]/, ' ' => '_', "'" => '').downcase
    mail_user = character.name.gsub(/[' ]/, ' ' => '.', "'" => '')

    mail_domain = ENV['DOKUWIKI_MAIL_DOMAIN']

    estimate = Zxcvbn.test(params[:password], [character.name, wiki_user])
    if estimate.score < 3
      feedback = estimate.feedback
      warning = feedback.warning || ''
      suggestions = feedback.suggestions.join(' ')

      message = []
      message << "Password rejected: #{warning}" unless warning.empty?
      message << "Tips: #{suggestions}" unless suggestions.empty?

      return render plain: message.join(' '), status: :bad_request
    end

    WikiUser.upsert(
      { character_id: @authenticated_account.id, user: wiki_user, hash: hash_for_dokuwiki(params[:password]), mail: "#{mail_user}@#{mail_domain}" },
      unique_by: :character_id
    )

    render json: {}, status: :no_content
  end

  def whoami
    account = @authenticated_account

    character = Character.find_by(id: account.id)

    characters = []
    characters << {
      id: character.id,
      name: character.name,
      corporation_id: nil
    }

    alts = AltCharacter.joins(:alt)
                       .where(account_id: account.id)
                       .select(:id, :name)

    alts.each do |alt|
      characters << {
        id: alt.attributes['id'],
        name: alt.name,
        corporation_id: nil
      }
    end

    access_levels = account.access.map(&:to_s)

    render json: {
      account_id: account.id,
      access: access_levels,
      characters: characters
    }
  end

  def logout
    cookies.permanent.encrypted[:current_user_id] = nil
    head :no_content, status: :ok
  end

  def login_url
    alt = params[:alt]
    fc = params[:fc]

    state = alt ? 'alt' : 'normal'

    scopes = [ESIClientService::PublicData, ESIClientService::Skills_ReadSkills_v1, ESIClientService::Clones_ReadImplants_v1]
    scopes += [ESIClientService::Fleets_ReadFleet_v1, ESIClientService::Fleets_WriteFleet_v1, ESIClientService::UI_OpenWindow_v1, ESIClientService::Search_v1] if fc

    esi_url = ENV['ESI_URL']
    client_id = ENV['EVE_ONLINE_SSO_CLIENT_ID']

    redirect_uri = "https://login.eveonline.com/v2/oauth/authorize?response_type=code&redirect_uri=#{esi_url}&client_id=#{client_id}&scope=#{scopes.join(' ')}&state=#{state}"

    render plain: redirect_uri
  end

  def callback
    character_id = esi_client.process_authorization_code(params[:code])

    affiliation_service.update_character_affiliation(character_id)

    if (ban = BanService.character_bans(character_id).first)
      payload = {
        category: ban.entity.category,
        expires_at: ban.revoked_at,
        reason: ban.public_reason
      }

      return render plain: payload, status: :forbidden
    end

    get_current_account

    logged_in_account =
      if params[:state].presence == "alt" && @authenticated_account && @authenticated_account.id != character_id
        if Admin.find_by(character_id: character_id)
          return render json: { error: 'Character is flagged as a main and cannot be added as an alt' }, status: :bad_request
        end

        AltCharacter.find_or_create_by!(account_id: @authenticated_account.id, alt_id: character_id)
        @authenticated_account.id
      else
        character_id
      end

    create_cookie(logged_in_account)

    render json: { success: true }, status: :ok
  end

  private

  def account_params
    params.require(:account).permit(:name, :email)
  end

  # Replace these service placeholders with your actual methods or services
  def esi_client
    @esi_client ||= ESIClientService.new
  end

  def affiliation_service
    @affiliation_service ||= AffiliationService.new
  end

  def create_cookie(user_id)
    cookies.permanent.encrypted[:current_user_id] = user_id
    # Replace with your actual method that creates and sets the cookie.
  end

  def hash_for_dokuwiki(password)
    BCrypt::Password.create(password, cost: BCrypt::Engine::DEFAULT_COST)
  end
end
