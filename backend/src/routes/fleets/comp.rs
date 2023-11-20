use crate::{core::auth::AuthenticatedAccount, app::Application, util::{madness::Madness, types::{Hull, Character}}};
use eve_data_core::TypeDB;
use rocket::serde::json::Json;
use serde::Serialize;
use sqlx::Row;
use std::{collections::HashMap, ptr::null};

#[derive(Serialize, Debug)]
struct FleetPosition {
    wing: String,
    squad: String,
    is_alt: bool,
    badges: Vec<String>
}

#[derive(Serialize, Debug)]
struct FleetMember {
    character: Character,
    hull: Hull,
    position: FleetPosition
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

    let id_list: String = character_ids.iter().map(|n| n.to_string()).collect::<Vec<String>>().join(", ");
    let query = format!("
    select
        a.CharacterId as character_id,
        ARRAY_AGG(b.name) as badges
        from badge_assignment a
        join badge b on a.BadgeId = b.id
        where a.CharacterId in ({})
        group by a.CharacterId;
    ", id_list);

    let badges: HashMap<i64, Vec<String>> = sqlx::query(&query)
    .fetch_all(app.get_db())
    .await?
    .into_iter().map(|row| {
        let character_id: i64 = row.get("character_id");
        let badges: Vec<String> = row.get("badges");
        (character_id, badges)
    }).collect();

    let squads: HashMap<i64, Vec<String>> = sqlx::query!(
        "SELECT squad_id, wing_id, category FROM fleet_squad WHERE fleet_id = $1",
        fleet_id
    )
    .fetch_all(app.get_db())
    .await?
    .into_iter()
    .map(|squad| (squad.squad_id, [squad.category, squad.wing_id.to_string()].to_vec()))
    .collect();

    let on_grid_wing = squads.values().next().unwrap().get(1).unwrap();

    let fleet_members = in_fleet
    .into_iter()
    .map(|r| FleetMember {
        character: Character {
            id: r.character_id,
            name: characters.remove(&r.character_id).map(|f| f.name).unwrap(),
            corporation_id: None,
        },
        hull: Hull {
            id: r.ship_type_id,
            name: match TypeDB::load_type(r.ship_type_id) {
                Ok(t) => t.name.to_string(),
                _ => "Unknown".to_string()
            }
        },
        position: FleetPosition {
            squad: match squads.get(&r.squad_id) {
                Some(v) => v.get(0).unwrap().to_string(),
                None => if r.squad_id == -1 {"logi".to_string()} else { if &(r.wing_id.to_string()) == on_grid_wing {"boxer".to_string()} else {"Off Grid".to_string()}},
            },
            wing: match squads
            .get(&r.squad_id) {
                Some(_) => "On Grid".to_string(),
                None => if &r.wing_id.to_string() == on_grid_wing {"On Grid".to_string() } else { "Off Grid".to_string() },
            },
            is_alt: match squads
            .get(&r.squad_id) {
                Some(v) => if v.get(0).unwrap() == "alt" {true} else {false},
                None => false,
            },
            badges: match badges.get(&r.character_id) {
                Some(b) => b.to_vec(),
                None => [].to_vec()
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
