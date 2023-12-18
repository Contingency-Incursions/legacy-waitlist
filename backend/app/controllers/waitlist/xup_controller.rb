# frozen_string_literal: true

module Waitlist
  class XupController < ApplicationController

    def xup
      input = params
      fits = FittingService::Fitting.from_eft(input[:eft])
      xups = [[input[:character_id], fits]]

      input[:dna].each do |dna_xup|
        fit = FittingService::Fitting.from_dna(dna_xup[:dna])
        xups << [dna_xup[:character_id], fit]
      end if input[:dna].present?

      begin
        Waitlist::XupService.process_xups(@authenticated_account, xups, input[:is_alt])
      # rescue => e
      #   render plain: e.message, status: :bad_request and return
      end
      render status: :ok
    end

  end
end
