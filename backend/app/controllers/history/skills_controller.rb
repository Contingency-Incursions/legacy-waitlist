# frozen_string_literal: true

class History::SkillsController < ApplicationController
  def skills
    authorize_character!(params[:character_id], "skill-history-view")

    # Fetch the relevant_skills hash from the tdf_skills::skill_data from your application
    relevance = SkillsData.get_skills_data.relevant_skills

    # Replace this call to your actual implementation
    id_lookup = SkillsData.get_skills_data.id_lookup

    # Assuming the model for the 'skill_history' table is 'SkillHistory'
    history_entries = SkillHistory.where(character_id: params[:character_id])
                                  .order(id: :desc)
                                  .filter { |entry| relevance.include?(entry.skill_id) }

    history = history_entries.map do |entry|
      {
        skill_id: entry.skill_id,
        old_level: entry.old_level,
        new_level: entry.new_level,
        logged_at: entry.logged_at,
        name: id_lookup[entry.skill_id]
      }
    end

    # Replace this call to your actual implementation
    name_lookup = SkillsData.get_skills_data.name_lookup

    render json: {
      history: history,
      ids: name_lookup
    }
  end
end
