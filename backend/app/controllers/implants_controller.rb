# frozen_string_literal: true

class ImplantsController < ApplicationController
  def list_implants
    authorize_character!(params[:character_id], nil)
    implants = ImplantData.get_implants(params[:character_id])
    render json: {implants: implants}, status: :ok
  end
end
