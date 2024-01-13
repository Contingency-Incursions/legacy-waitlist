use itertools::Itertools;
use rocket::serde::json::Json;
use serde::{Deserialize, Serialize};
use zxcvbn::{zxcvbn, ZxcvbnError};

use crate::app;
use crate::core::auth::{AuthenticatedAccount, AuthenticationError, CookieSetter};
use crate::core::esi::ESIScope;
use crate::util::{madness::Madness, types};

#[derive(Deserialize)]
struct SetWikiPasswordRequest {
    password: String,
}

fn hash_for_dokuwiki(password: &[u8]) -> String {
    bcrypt::hash_with_result(password, bcrypt::DEFAULT_COST)
        .unwrap()
        .format_for_version(bcrypt::Version::TwoY)
}

#[post("/api/auth/wiki", data = "<input>")]
async fn set_wiki_passwd(
    app: &rocket::State<app::Application>,
    account: AuthenticatedAccount,
    input: Json<SetWikiPasswordRequest>,
) -> Result<(), Madness> {
    account.require_one_of_access("waitlist-tag:TRAINEE,wiki-editor")?;

    let character = sqlx::query!("SELECT name FROM character WHERE id = $1", account.id)
        .fetch_one(app.get_db())
        .await?;

    static SPACE: char = ' ';
    static TICK: char = '\'';

    let wiki_user = character
        .name
        .replace(SPACE, "_")
        .replace(TICK, "")
        .to_lowercase();
    let mail_user = character.name.replace(SPACE, ".").replace(TICK, "");
    let mail_domain = &app.config.dokuwiki.mail_domain;

    let estimate = zxcvbn(input.password.as_ref(), &[&character.name, &wiki_user]).map_err(
        |err| match err {
            ZxcvbnError::BlankPassword => {
                Madness::BadRequest("Password rejected: Empty password not allowed".to_string())
            }
            err => Madness::GeneralError(err),
        },
    )?;

    if estimate.score() < 3 {
        let feedback = estimate.feedback().as_ref().unwrap();
        let warning = feedback.warning().map_or("".to_string(), |x| x.to_string());
        let suggestions: String = Itertools::intersperse(
            feedback.suggestions().iter().map(|x| x.to_string()),
            " ".to_string(),
        )
        .collect();

        let mut message = String::with_capacity(26 + warning.len() + suggestions.len());
        if !warning.is_empty() {
            message.push_str("Password rejected: ");
            message.push_str(&warning);
        } else {
            message.push_str("Password rejected.");
        }
        if !suggestions.is_empty() {
            message.push_str(" Tips: ");
            message.push_str(&suggestions);
        }

        return Err(Madness::BadRequest(message));
    }

    sqlx::query!(
        "INSERT INTO wiki_user (character_id, \"user\", hash, mail) VALUES ($1, $2, $3, $4) ON CONFLICT (character_id)
        DO UPDATE
        SET \"user\" = excluded.user,
        hash = excluded.hash,
        mail = excluded.mail;",
        account.id,
        wiki_user,
        hash_for_dokuwiki(input.password.as_ref()),
        format!("{mail_user}@{mail_domain}"),
    )
    .execute(app.get_db())
    .await?;

    Ok(())
}

#[derive(Serialize)]
struct WhoamiResponse {
    account_id: i64,
    access: Vec<&'static str>,
    characters: Vec<types::Character>,
}

#[get("/api/auth/whoami")]
async fn whoami(
    app: &rocket::State<app::Application>,
    account: AuthenticatedAccount,
) -> Result<Json<WhoamiResponse>, Madness> {
    let character = sqlx::query!("SELECT id, name FROM character WHERE id = $1", account.id)
        .fetch_one(app.get_db())
        .await?;
    let mut characters = vec![types::Character {
        id: character.id,
        name: character.name,
        corporation_id: None,
    }];

    let alts = sqlx::query!(
        "SELECT id, name FROM alt_character JOIN character ON alt_character.alt_id = character.id WHERE account_id = $1",
        account.id
    )
    .fetch_all(app.get_db())
    .await?;

    for alt in alts {
        characters.push(types::Character {
            id: alt.id,
            name: alt.name,
            corporation_id: None,
        });
    }

    let mut access_levels = Vec::new();
    for key in account.access {
        access_levels.push(key.as_str());
    }

    Ok(Json(WhoamiResponse {
        account_id: account.id,
        access: access_levels,
        characters,
    }))
}

#[get("/api/auth/logout")]
async fn logout<'r>(
    app: &rocket::State<app::Application>,
    account: Option<AuthenticatedAccount>,
) -> Result<CookieSetter, Madness> {
    if let Some(account) = account {
        sqlx::query!(
            "DELETE FROM alt_character WHERE account_id = $1 OR alt_id = $2",
            account.id,
            account.id
        )
        .execute(app.get_db())
        .await?;
    }

    Ok(CookieSetter(
        "".to_string(),
        app.config.esi.url.starts_with("https:"),
    ))
}

#[get("/api/auth/login_url?<alt>&<fc>")]
fn login_url(alt: bool, fc: bool, app: &rocket::State<app::Application>) -> String {
    let state = match alt {
        true => "alt",
        false => "normal",
    };

    let mut scopes = vec![
        ESIScope::PublicData,
        ESIScope::Skills_ReadSkills_v1,
        ESIScope::Clones_ReadImplants_v1,
    ];
    if fc {
        scopes.extend(vec![
            ESIScope::Fleets_ReadFleet_v1,
            ESIScope::Fleets_WriteFleet_v1,
            ESIScope::UI_OpenWindow_v1,
            ESIScope::Search_v1,
        ])
    }

    format!(
        "https://login.eveonline.com/v2/oauth/authorize?response_type={}&redirect_uri={}&client_id={}&scope={}&state={}",
        "code",
        app.config.esi.url,
        app.config.esi.client_id,
        scopes.iter().map(|s| s.as_str()).join("%20"),
        state
    )
}

#[derive(Deserialize)]
struct CallbackData<'r> {
    code: &'r str,
    state: Option<&'r str>,
}

#[derive(Serialize)]
struct PublicBanPayload {
    category: String,
    expires_at: Option<i64>,
    reason: Option<String>,
}

#[post("/api/auth/cb", data = "<input>")]
async fn callback(
    input: Json<CallbackData<'_>>,
    app: &rocket::State<app::Application>,
    account_raw: Result<AuthenticatedAccount, AuthenticationError>,
) -> Result<CookieSetter, Madness> {
    let account = match account_raw {
        Err(AuthenticationError::MissingCookie) => None,
        Err(AuthenticationError::InvalidToken) => None,
        Err(AuthenticationError::DatabaseError(e)) => return Err(e.into()),
        Ok(acc) => Some(acc),
    };

    let character_id = app
        .esi_client
        .process_authorization_code(input.code)
        .await?;

    // Update the character's corporation and aliance information
    app.affiliation_service
        .update_character_affiliation(character_id)
        .await?;

    if let Some(ban) = app.ban_service.character_bans(character_id).await? {
        let ban = ban.first().unwrap();

        let payload = PublicBanPayload {
            category: ban.entity.to_owned().unwrap().category,
            expires_at: ban.revoked_at,
            reason: ban.public_reason.to_owned(),
        };

        if let Ok(json) = serde_json::to_string(&payload) {
            return Err(Madness::Forbidden(json));
        }
        return Err(Madness::BadRequest("You cannot login due to a ban. An error occurred when trying to retrieve the details, please contact council for more information.".to_string()));
    }

    let logged_in_account = if input.state.is_some()
        && input.state.unwrap() == "alt"
        && account.is_some()
    {
        let account = account.unwrap();
        if account.id != character_id {
            let is_admin = sqlx::query!(
                "SELECT character_id FROM admin WHERE character_id = $1",
                character_id
            )
            .fetch_optional(app.get_db())
            .await?;

            if is_admin.is_some() {
                return Err(Madness::BadRequest(
                    "Character is flagged as a main and cannot be added as an alt".to_string(),
                ));
            }

            sqlx::query!(
                    "INSERT INTO alt_character (account_id, alt_id) VALUES ($1, $2) ON CONFLICT (account_id, alt_id)
                    DO NOTHING;",
                    account.id,
                    character_id
                )
                .execute(app.get_db())
                .await?;
        }
        account.id
    } else {
        character_id
    };

    Ok(crate::core::auth::create_cookie(app, logged_in_account))
}

pub fn routes() -> Vec<rocket::Route> {
    routes![whoami, logout, login_url, callback, set_wiki_passwd]
}
