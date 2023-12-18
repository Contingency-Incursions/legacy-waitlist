class AddSkillsLastCheckedToCharacter < ActiveRecord::Migration[7.1]
  def change
    add_column :character, :skills_last_checked, :datetime
  end
end
