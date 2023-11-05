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

    // let category_lookup: HashMap<_, _> = crate::data::categories::categories()
    //     .iter()
    //     .map(|c| (&c.id as &str, &c.name))
    //     .collect();

    // let squads: HashMap<i64, String> = sqlx::query!(
    //     "SELECT squad_id, category FROM fleet_squad WHERE fleet_id = $1",
    //     fleet_id
    // )
    // .fetch_all(app.get_db())
    // .await?
    // .into_iter()
    // .map(|squad| (squad.squad_id, squad.category))
    // .collect();

    // Ok(Json(FleetMembersResponse {
    //     members: in_fleet
    //         .into_iter()
    //         .map(|member| FleetMembersMember {
    //             id: member.character_id,
    //             name: characters.remove(&member.character_id).map(|f| f.name),
    //             ship: Hull {
    //                 id: member.ship_type_id,
    //                 name: TypeDB::name_of(member.ship_type_id).unwrap(),
    //             },
    //             wl_category: squads
    //                 .get(&member.squad_id)
    //                 .and_then(|s| category_lookup.get(s.as_str()))
    //                 .map(|s| s.to_string()),
    //         })
    //         .collect(),
    // }))

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
