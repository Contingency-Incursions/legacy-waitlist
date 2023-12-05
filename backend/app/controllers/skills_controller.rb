# frozen_string_literal: true

class SkillsController < ApplicationController

  def list_skills
    char_id = params[:character_id]
    authorize_character!(char_id, 'skill-view')

    skills = SkillsData.load_skills(char_id)
    relevant_skills = {}
    skills_data = SkillsData.get_skills_data
    skills_data.relevant_skills.each do |skill|
      relevant_skills[skill] = skills.get(skill)
    end

    render json: {
      current: relevant_skills,
      ids: skills_data.name_lookup,
      categories: skills_data.categories,
      requirements: skills_data.requirements
    }

  end
end
