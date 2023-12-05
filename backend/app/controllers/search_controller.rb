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
end
