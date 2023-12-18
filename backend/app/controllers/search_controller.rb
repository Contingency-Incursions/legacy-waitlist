# frozen_string_literal: true

class SearchController < ApplicationController
  def query
    AuthService.requires_access(@authenticated_account, 'search')

    search_like = "%#{params[:query]}%"
    characters = Character.where("name ILIKE ?", search_like).map do |character|
      {
        id: character.id,
        name: character.name,
        corporation_id: nil #assuming we want to explicitly set this as nil as in rust
      }
    end

    render json: { query: params[:query], results: characters }
  end

  def esi_search
    begin
      AuthService.requires_access(@authenticated_account, 'fleet-invite')
      authorize_character!(@authenticated_account.id, nil)

      categories = ["character", "corporation", "alliance"]
      unless categories.include?(params[:category])
        return render plain: "Body parameter \"category\" must be one of [\"character\", \"corporation\", \"alliance\"]", status: :bad_request
      end

      account_id = @authenticated_account.id
      category = params[:category]
      search = params[:search]
      strict = params[:strict] || false

      url = "/latest/characters/#{account_id}/search/?categories=#{category}&search=#{search}&strict=#{strict}"
      esi_response = esi_client.get(url, @authenticated_account.id, ESIClientService::Search_v1) # Asume the REST client is already defined

      if esi_response[category].present?
        render json: esi_response[category]
      else
        render json: []
      end

    rescue => e
      render plain: e.message, status: :bad_request
    end
  end

  private
  def esi_client
    @esi_client ||= ESIClientService.new
  end
end
