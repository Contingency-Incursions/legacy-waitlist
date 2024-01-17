use crate::util::types::{Character, System};
use crate::{app::Application, core::auth::AuthenticatedAccount, util::madness::Madness};
use eve_data_core::TypeDB;
use rocket::serde::json::Json;
use serde::{Deserialize, Serialize};

use super::notify;

#[derive(Debug, Serialize)]
struct FleetSettings {
    boss: Character,
    boss_system: Option<System>,
    size: i64,
    size_max: i64,
    visible: bool,
    error_count: i64,
}

#[derive(Debug, Deserialize)]
struct FleetBossReq {
    fleet_boss: i64,
}

#[derive(Debug, Deserialize)]
struct FleetVisibilityReq {
    visible: bool,
}

#[derive(Debug, Deserialize)]
struct FleetSizeReq {
    max_size: i64,
}

#[get("/api/v2/fleets/<fleet_id>")]
async fn get_fleet(
    account: AuthenticatedAccount,
    app: &rocket::State<Application>,
    fleet_id: i64,
) -> Result<Json<FleetSettings>, Madness> {
    account.require_access("fleet-view")?;

    if let Some(fleet) = sqlx::query!(
        "SELECT
            fleet.id,
            fleet.boss_system_id,
            fleet.visible as \"visible:bool\",
            fc.id as boss_id,
            fc.name  as boss_name,
            fleet.max_size,
            fleet.error_count,
            COUNT(DISTINCT fa.character_id) as size
        FROM fleet
        JOIN character as fc ON fc.id=fleet.boss_id
        LEFT JOIN fleet_activity as fa ON fa.fleet_id=fleet.id and fa.has_left = false
        WHERE fleet.id = $1
        GROUP BY fleet.id, fc.id",
        fleet_id
    )
    .fetch_optional(app.get_db())
    .await?
    {
        return Ok(Json(FleetSettings {
            boss: Character {
                id: fleet.boss_id,
                name: fleet.boss_name,
                corporation_id: None,
            },
            boss_system: fleet.boss_system_id.map(|system_id| System {
                id: system_id,
                name: match TypeDB::name_of_system(system_id) {
                    Ok(name) => name.to_string(),
                    _ => "Unknown System".to_string(),
                },
            }),
            size: fleet.size.unwrap(),
            size_max: fleet.max_size,
            visible: fleet.visible,
            error_count: fleet.error_count,
        }));
    }

    Err(Madness::NotFound("Fleet not found."))
}

#[post("/api/v2/fleets/<fleet_id>/boss", data = "<body>")]
async fn set_boss(
    account: AuthenticatedAccount,
    app: &rocket::State<Application>,
    fleet_id: i64,
    body: Json<FleetBossReq>,
) -> Result<&'static str, Madness> {
    account.require_access("fleet-view")?;

    if sqlx::query!("SELECT * FROM fleet WHERE id=$1", fleet_id)
        .fetch_optional(app.get_db())
        .await?
        .is_some()
    {
        sqlx::query!(
            "UPDATE fleet SET boss_id=$1, error_count=0 WHERE id=$2",
            body.fleet_boss,
            fleet_id
        )
        .execute(app.get_db())
        .await?;
    }

    notify::fleets_updated(app, "fleet_settings", Some(fleet_id)).await?;

    Ok("Ok")
}

#[post("/api/v2/fleets/<fleet_id>/visibility", data = "<body>")]
async fn set_visibility(
    account: AuthenticatedAccount,
    app: &rocket::State<Application>,
    fleet_id: i64,
    body: Json<FleetVisibilityReq>,
) -> Result<&'static str, Madness> {
    account.require_access("fleet-view")?;

    if sqlx::query!("SELECT * FROM fleet WHERE id=$1", fleet_id)
        .fetch_optional(app.get_db())
        .await?
        .is_some()
    {
        sqlx::query!(
            "UPDATE fleet SET visible=$1 WHERE id=$2",
            body.visible,
            fleet_id
        )
        .execute(app.get_db())
        .await?;
    }

    notify::fleets_updated(app, "fleet_settings", Some(fleet_id)).await?;
    notify::waitlist_state(app, "visibility").await?;

    Ok("Ok")
}

#[post("/api/v2/fleets/<fleet_id>/size", data = "<body>")]
async fn set_size(
    account: AuthenticatedAccount,
    app: &rocket::State<Application>,
    fleet_id: i64,
    body: Json<FleetSizeReq>,
) -> Result<&'static str, Madness> {
    account.require_access("fleet-view")?;

    if sqlx::query!("SELECT * FROM fleet WHERE id=$1", fleet_id)
        .fetch_optional(app.get_db())
        .await?
        .is_some()
    {
        sqlx::query!(
            "UPDATE fleet SET max_size=$1 WHERE id=$2",
            body.max_size,
            fleet_id
        )
        .execute(app.get_db())
        .await?;
    }

    notify::fleets_updated(app, "fleet_settings", Some(fleet_id)).await?;

    Ok("Ok")
}

pub fn routes() -> Vec<rocket::Route> {
    routes![
        get_fleet,      // GET      /api/v2/fleets/<fleet_id>
        set_boss,       // POST     /api/v2/fleets/<fleet_id>/boss
        set_size,       // POST     /api/v2/fleets/<fleet_id>/size
        set_visibility  // POST     /api/v2/fleets/<fleet_id>/visibility
    ]
}
