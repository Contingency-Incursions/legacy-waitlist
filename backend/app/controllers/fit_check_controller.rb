# frozen_string_literal: true

class FitCheckController < ApplicationController

  class XupRequest
    attr_accessor :character_id, :eft
  end

  class FitResult
    attr_accessor :approved, :fit_analysis, :dna
  end

  class PilotData
    attr_accessor :implants, :time_in_fleet, :skills, :access_keys, :id
  end
  def fit_check
    # Assuming strong params and input params are same XupRequest
    input = xup_request_params
    fits = FittingService::Fitting.from_eft(input[:eft])

    pilot = PilotData.new.tap do |pd|
      pd.implants = ImplantData.get_implants(input[:character_id])
      pd.time_in_fleet = 0
      pd.skills = SkillsData.load_skills(input[:character_id])
      pd.access_keys = @authenticated_account.access
      pd.id = input[:character_id]
    end

    badges = Badge.joins(:badge_assignments)
                  .where("badge_assignment.characterid = ?", input[:character_id])
                  .pluck(:name)

    result = []


    fits.each do |fit|
      fit_checked = FittingService::FitChecker.check(pilot, fit, badges)
      error = fit_checked[:errors].first
      # Handle possible errors, assuming Madness::BadRequest can be replaced with RuntimeError

      return render status: :bad_request, plain: error if error.present?

      result.push({
                    approved: fit_checked[:approved],
                    fit_analysis: fit_checked[:analysis],
                    dna: FittingService::Fitting.to_dna(fit)
                  })
    end






    render json: result
  end

  private

  def xup_request_params
    params.permit(:character_id, :eft)
  end
end
