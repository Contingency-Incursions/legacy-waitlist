# frozen_string_literal: true

class FittingsController < ApplicationController

  def index
    fittingformatted = {}
    id = 0
    FitsData.fits.values.flatten.each do |fit|
      next if fit[:hidden]

      fitname = fit[:name].clone
      dna = FittingService::Fitting.to_dna(fit[:fit])
      fittingformatted[id] ||= {name: fitname, dna: dna}
      id += 1
    end

    logirules = []
    CategoriesData.rules.each do |rule|
      logirules.push(rule[0]) if rule[1] == 'logi'
    end

    render json: {
      fittingdata: fittingformatted.values,
      notes: Rails.application.config.fitnotes['notes'],
      rules: logirules,
    }
  end
end
