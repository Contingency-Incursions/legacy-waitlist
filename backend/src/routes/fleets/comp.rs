use crate::{core::auth::AuthenticatedAccount, app::Application, util::{madness::Madness, types::{Hull, Character}}};
use eve_data_core::TypeDB;
use rocket::serde::json::Json;
use serde::Serialize;

#[derive(Serialize, Debug)]
struct FleetMember {
    character: Character,
    hull: Hull
}

#[get("/api/v2/fleets/<fleet_id>/comp")]
async fn fleet(
    account: AuthenticatedAccount,
    app: &rocket::State<Application>,
    fleet_id: i64
) -> Result<Json<Vec<FleetMember>>, Madness> {
    account.require_access("fleet-view")?;


    let fleet = match sqlx::query!("SELECT boss_id FROM fleet WHERE id = $1", fleet_id)
        .fetch_optional(app.get_db())
        .await?
    {
        Some(fleet) => fleet,
        None => return Err(Madness::NotFound("Fleet not configured")),
    };

    let in_fleet =
        crate::core::esi::fleet_members::get(&app.esi_client, fleet_id, fleet.boss_id).await?;
    let character_ids: Vec<_> = in_fleet.iter().map(|member| member.character_id).collect();
    let mut characters = crate::data::character::lookup(app.get_db(), &character_ids).await?;

    let fleet_members = in_fleet
    .into_iter()
    .map(|r| FleetMember {
        character: Character {
            id: r.character_id,
            name: characters.remove(&r.character_id).map(|f| f.name).unwrap(),
            corporation_id: None
        },
        hull: Hull {
            id: r.ship_type_id,
            name: match TypeDB::load_type(r.ship_type_id) {
                Ok(t) => t.name.to_string(),
                _ => "Unknown".to_string()
            }
        }
    })
    .collect();

    Ok(Json(fleet_members))
}



pub fn routes() -> Vec<rocket::Route> {
    routes![
        fleet,      //  GET    /api/v2/fleets/<fleet_id>/comp
    ]
}
