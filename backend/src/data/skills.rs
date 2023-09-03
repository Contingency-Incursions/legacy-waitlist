use std::collections::HashMap;

use serde::Deserialize;

use crate::core::esi::{ESIClient, ESIError, ESIScope};
use eve_data_core::{SkillLevel, TypeID};
use crate::tdf::skills as tdf_skills;

#[derive(Deserialize, Debug)]
struct SkillResponseSkill {
    skill_id: TypeID,
    trained_skill_level: SkillLevel,
    active_skill_level: SkillLevel,
}

#[derive(Deserialize, Debug)]
struct SkillResponse {
    skills: Vec<SkillResponseSkill>,
}

#[derive(thiserror::Error, Debug)]
pub enum SkillsError {
    #[error("ESI error")]
    ESIError(#[from] ESIError),
    #[error("database error")]
    Database(#[from] sqlx::Error),
}

pub struct Skills(pub HashMap<TypeID, SkillLevel>);

impl Skills {
    pub fn get(&self, skill_id: TypeID) -> SkillLevel {
        match self.0.get(&skill_id) {
            Some(level) => *level,
            None => 0,
        }
    }
}

pub async fn load_skills(
    esi_client: &ESIClient,
    db: &crate::DB,
    character_id: i64,
) -> Result<Skills, SkillsError> {
    let skills: SkillResponse = esi_client
        .get(
            &format!("/v4/characters/{}/skills/", character_id),
            character_id,
            ESIScope::Skills_ReadSkills_v1,
        )
        .await?;

    let last_known_skills_q = sqlx::query!(
        "SELECT * FROM skill_current WHERE character_id = ?",
        character_id
    )
    .fetch_all(db)
    .await?;
    let mut last_known_skills = HashMap::new();
    for skill in last_known_skills_q {
        last_known_skills.insert(skill.skill_id as TypeID, skill.level as SkillLevel);
    }

    let mut tx = db.begin().await?;
    let now = chrono::Utc::now().timestamp();

    let tracked_skills = &tdf_skills::skill_data().relevant_skills;

    let mut result = HashMap::new();
    for skill in skills.skills {
        // Security fix: Do not track non-relevant skills.
        // SEE: https://github.com/the-outuni-project/legacy-waitlist/issues/41
        if !tracked_skills.contains(&skill.skill_id) {
            continue;
        }
        result.insert(
            skill.skill_id as TypeID,
            skill.active_skill_level as SkillLevel,
        );

        let on_record = last_known_skills.get(&skill.skill_id);
        if let Some(on_record) = on_record {
            if *on_record == skill.trained_skill_level {
                // Match: skill didn't change
                continue;
            }

            sqlx::query!(
                "INSERT INTO skill_history (character_id, skill_id, old_level, new_level, logged_at) VALUES (?, ?, ?, ?, ?)",
                character_id, skill.skill_id, *on_record, skill.trained_skill_level, now
            ).execute(&mut tx).await?;
        } else if !last_known_skills.is_empty() {
            sqlx::query!(
                "INSERT INTO skill_history (character_id, skill_id, old_level, new_level, logged_at) VALUES (?, ?, 0, ?, ?)",
                character_id, skill.skill_id, skill.trained_skill_level, now
            ).execute(&mut tx).await?;
        }

        sqlx::query!(
            "REPLACE INTO skill_current (character_id, skill_id, level) VALUES (?, ?, ?)",
            character_id,
            skill.skill_id,
            skill.trained_skill_level
        )
        .execute(&mut tx)
        .await?;
    }

    tx.commit().await?;

    Ok(Skills(result))
}
