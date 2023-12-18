# frozen_string_literal: true

require 'httparty'
require 'json'

class ESIError < StandardError; end

class DatabaseError < ESIError
  def initialize(message = "Database error")
    super
  end
end

class HTTPError < ESIError
  def initialize(message = "ESI HTTP error")
    super
  end
end

class StatusError < ESIError
  def initialize(code)
    super("ESI returned #{code}")
  end
end

class WithMessageError < ESIError

  attr_accessor :code
  def initialize(code, message)
    super(message)
    @code = code
  end
end

class NoTokenError < ESIError
  def initialize(message = "No ESI token found")
    super
  end
end

class MissingScopeError < ESIError
  def initialize(message = "Missing ESI scope")
    super
  end
end

class ESIError::StatusIs400 < ESIError
end

class ESIError::MissingScope < ESIError
end

class EsiErrorReason
  attr_accessor :error, :details

  def initialize(error, details)
    @error = error
    @details = details
  end

  def self.new_from_json(body)
    begin
      parsed_json = JSON.parse(body)
      error = parsed_json['error']
      EsiErrorReason.new(error, '')
    rescue JSON::ParserError => e
      EsiErrorReason.new('Failed to parse ESI error reason', e.message)
    end
  end
end

class ESIClientService
  PublicData = 'publicData'
  Fleets_ReadFleet_v1 = 'esi-fleets.read_fleet.v1'
  Fleets_WriteFleet_v1 = 'esi-fleets.write_fleet.v1'
  UI_OpenWindow_v1 = 'esi-ui.open_window.v1'
  Skills_ReadSkills_v1 = 'esi-skills.read_skills.v1'
  Clones_ReadImplants_v1 = 'esi-clones.read_implants.v1'
  Search_v1 = 'esi-search.search_structures.v1'
  include HTTParty

  base_uri 'https://esi.evetech.net'

  def initialize
    @client_id = ENV['EVE_ONLINE_SSO_CLIENT_ID']
    @client_secret = ENV['EVE_ONLINE_SSO_SECRET_KEY']
  end

  def process_authorization_code(code)
    result = self.process_auth("authorization_code", code, nil)

    previous_token = RefreshToken.find_by(character_id: result[:character_id])

    if previous_token
      merged_scopes = result[:scopes].clone
      extra_scopes = split_scopes(previous_token.scopes)

      extra_scopes.each do |extra_scope|
        merged_scopes << extra_scope
      end

      merged_scopes.uniq!

      second_attempt = begin
                         self.process_auth("refresh_token", result[:refresh_token], merged_scopes)
                       rescue => e
                         if e.is_a?(ESIError::StatusIs400)
                           result
                         else
                           raise e
                         end
                       end

      result = second_attempt
    end

    self.save_auth(result)
    result[:character_id]
  rescue => e
    raise ESIError.new(e.message)
  end

  def save_auth(auth)
    begin
      Character.transaction do
        unless Character.find_by_id(auth[:character_id])
          Character.create!(id: auth[:character_id], name: auth[:character_name])
        end

        AccessToken.upsert(
          { character_id: auth[:character_id],
            access_token: auth[:access_token],
            expires: auth[:access_token_expiry],
            scopes: auth[:scopes].join(' ') },
          unique_by: :character_id
        )

        RefreshToken.upsert(
          { character_id: auth[:character_id],
            refresh_token: auth[:refresh_token],
            scopes: auth[:scopes].join(' ') },
          unique_by: :character_id
        )
      end
    rescue => e
      raise ESIError.new(e.message)
    end
  end


  # Implementing ESIRawClient's get method:
  def get(url, char_id, scope)
    access_token = get_access_token(char_id, scope) # You will need to define an access_token method

    headers = { 'Authorization' => "Bearer #{access_token}" }
    response = self.class.get(url, headers: headers)

    if response.success?
      JSON.parse(response.body)
    else
      log_response_error(response)
    end
  end

  def delete(url, character_id, scope)
    access_token = get_access_token(character_id, scope)

    headers = { 'Authorization' => "Bearer #{access_token}" }
    response = self.class.delete(url, headers: headers)

    unless response.success?
      log_response_error(response)
    end
  end

  def put(url, input, character_id, scope)
    access_token = get_access_token(character_id, scope)

    headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
    response = self.class.put(url, headers: headers, body: input.to_json)

    unless response.success?
      log_response_error(response)
    end
  end

  def post(url, input, character_id, scope)
    access_token = get_access_token(character_id, scope)

    headers = {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
    response = self.class.post(url, headers: headers, body: input.to_json)

    if response.success?
      JSON.parse(response.body)
    else
      log_response_error(response)
    end
  end

  def post_204(url, input, char_id, scope)
    access_token = get_access_token(char_id, scope)

    headers = { 'Authorization' => "Bearer #{access_token}" }
    response = self.class.post(url, {headers: headers, body: input.to_json})

    unless response.success?
      log_response_error(response)
    end

  end

  def get_unauthenticated(path)
    self.class.get(path)
  rescue => e
    # You have to decide what to do with the exception
    raise e
  end

  private

  def log_response_error(response)
    unless response.success?
      Rails.logger.warn("#{response.code}: #{response.body}\nReq URI: #{response.uri}\nHeaders: #{response.headers.inspect}")
      payload = EsiErrorReason.new_from_json(response.body)

      raise WithMessageError.new(response.code, payload.error)
    end
    response
  rescue HTTParty::Error => e
    Rails.logger.error e
  end

  def access_token_raw(character_id)
    access_token = AccessToken.find_by_character_id(character_id)
    if access_token && access_token.expires >= DateTime.now.utc.to_i
      scopes = split_scopes(access_token.scopes)
      return access_token.access_token, scopes
    end

    refresh = RefreshToken.find_by_character_id(character_id)

    if refresh.nil?
      raise ESIError.new("NoToken")
    end

    refresh_scopes = split_scopes(refresh.scopes)

    # You would need to define more specific methods instead of `process_auth` and `save_auth`.
    begin
      refreshed = process_auth('refresh_token', refresh.refresh_token, refresh_scopes)
      save_auth(refreshed)

      [refreshed[:access_token], refreshed[:scopes]]
    rescue ESIError => e
      if e.message === '400'
        ActiveRecord::Base.transaction do
          AccessToken.where(character_id: character_id).destroy_all
          RefreshToken.where(character_id: character_id).destroy_all
        end
        raise ESIError.new("NoToken")
      else
        raise e
      end
    end
  end

  def get_access_token(character_id, scope)
    token, scopes = access_token_raw(character_id)
    unless scopes.include?(scope.to_s)
      raise ESIError.new('MissingScope')
    end

    token
  end

  def process_auth(grant_type, token, scopes=nil)
    token = self.process_oauth_token(grant_type, token, scopes)
    character_id, name, scopes = self.process_verify(token[:access_token])
    {
      character_id: character_id,
      character_name: name,
      access_token: token[:access_token],
      access_token_expiry: token[:access_token_expiry],
      refresh_token: token[:refresh_token],
      scopes: scopes
    }
  rescue => e
    raise ESIError.new(e.message)
  end

  def process_oauth_token(grant_type, token, scopes=nil)
    scope_str = scopes ? scopes.join(' ') : nil

    request_data = {
      grant_type: grant_type,
      refresh_token: (grant_type == "refresh_token" ? token : nil),
      code: (grant_type == "refresh_token" ? nil : token),
      scope: scope_str
    }.compact

    response = HTTParty.post("https://login.eveonline.com/v2/oauth/token",
                             basic_auth: { username: @client_id, password: @client_secret },
                             body: request_data)

    raise ESIError.new('Error from EVE Online') if response.code != 200

    parsed_response = JSON.parse(response.body)

    {
      character_id: parsed_response['character_id'],
      character_name: parsed_response['character_name'],
      access_token: parsed_response['access_token'],
      access_token_expiry: (Time.now.utc.to_i + parsed_response['expires_in'].to_i / 2),
      refresh_token: parsed_response['refresh_token'],
      scopes: parsed_response['scopes']
    }
  rescue => e
    raise ESIError.new(e.message)
  end

  def process_verify(access_token)
    response = HTTParty.get(
      "https://login.eveonline.com/oauth/verify",
      headers: { "Authorization" => "Bearer #{access_token}" }
    )

    raise ESIError.new('Error from EVE Online') if response.code != 200

    parsed_response = JSON.parse(response.body)

    character_id = parsed_response['CharacterID']
    character_name = parsed_response['CharacterName']
    scopes = split_scopes(parsed_response['Scopes'])

    [character_id, character_name, scopes]
  rescue => e
    raise ESIError.new(e.message)
  end

  def split_scopes(input)
    input.split(' ').reject(&:empty?).uniq
  end

end
