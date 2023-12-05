# frozen_string_literal: true

class WindowController < ApplicationController
  def create
    authorize_character!(params[:character_id], nil)

    esi_client.post_204("/v1/ui/openwindow/information/?target_id=#{params[:target_id]}",
                                   {},
                                   params[:character_id], ESIClientService::UI_OpenWindow_v1)
    render json: {}, status: :no_content
  rescue => e
    render plain: e.message, status: :unprocessable_entity
  end

  private

  def esi_client
    @esi_client ||= ESIClientService.new
  end
end
