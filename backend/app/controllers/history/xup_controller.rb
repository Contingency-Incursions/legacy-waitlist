# frozen_string_literal: true

module History
  class XupController < ApplicationController
    def index
      authorize_character!(params[:character_id], "fit-history-view")

      @xup_history_lines = FitHistory
                             .joins(:fitting, :implant_set)
                             .where(character_id: params[:character_id])
                             .order(id: :desc)
                             .map do |xup|
        {
          logged_at: xup.logged_at,
          dna: xup.fitting.dna,
          implants: xup.implant_set.implants.split(':').reject(&:empty?),
          hull: {
            id:  xup.fitting.hull
          },
        }
      end

      mappings = InvTypesService.names_of @xup_history_lines.map {|x| x[:hull][:id]}.uniq
      @xup_history_lines.each {|x| x[:hull][:name] = mappings[x[:hull][:id]] }

      #      name: InvTypesService.names_of([hull_id])[hull_id]

      render json: { xups: @xup_history_lines }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
