use std::collections::{BTreeMap, BTreeSet, btree_map::Entry};

use rocket::serde::json::{Json, Value};
use serde::Serialize;

use crate::{
    app::Application,
    core::auth::AuthenticatedAccount,
    data,
    util::{
        madness::Madness,
        types::{Character, Hull},
    },
};
use eve_data_core::{TypeDB, TypeID};

#[derive(Debug, Serialize)]
struct WaitlistResponse {
    open: bool,
    waitlist: Option<Vec<WaitlistEntry>>,
    categories: Vec<&'static str>,
}

#[derive(Debug, Serialize)]
struct FleetHours {
    total: i64,
    bastion: i64
}


#[derive(Debug, Serialize)]
struct WaitlistEntry {
    id: i64,
    fits: Vec<WaitlistEntryFit>,
    character: Option<Character>,
    joined_at: i64,
    can_remove: bool,
    fleet_time: FleetHours
}

#[derive(Debug, Serialize)]
struct WaitlistEntryFit {
    id: i64,
    approved: bool,
    state: String,
    category: String,
    hull: Hull,
    character: Option<Character>,
    tags: Vec<String>,
    hours_in_fleet: Option<i64>,
    review_comment: Option<String>,
    dna: Option<String>,
    implants: Option<Vec<TypeID>>,
    fit_analysis: Option<Value>,
    is_alt: bool,
}

async fn get_time_in_fleet(db: &crate::DB, character_id: i64) -> Result<FleetHours, sqlx::Error> {
    let result = sqlx::query!(
        "select
        hull,
        cast(sum(last_seen - first_seen) as bigint) as seconds
        from fleet_activity fa
        left join alt_character ac on ac.alt_id = fa.character_id
        where ac.account_id = $1 or fa.character_id = $1
        group by hull"
    , character_id)
    .fetch_all(db)
    .await?;

    let total_time: i64 = result.iter().map(|rec| rec.seconds.unwrap()).sum();
    let bastion_time: i64 = result.iter().filter(|r| r.hull == 28659 || r.hull == 28661).map(|rec| rec.seconds.unwrap()).sum();
    let fleet_time = FleetHours{
        total: total_time / 3600,
        bastion: bastion_time / 3600
    };
    Ok(fleet_time)
}


#[get("/api/v2/fleets/waitlist")]
async fn fleet_waitlist(
    app: &rocket::State<Application>,
    account: AuthenticatedAccount,
) -> Result<Json<WaitlistResponse>, Madness> {
    account.require_access("fleet-view")?;
    let waitlist_categories = data::categories::categories()
        .iter()
        .map(|cat| &(cat.name) as &str)
        .collect();
    let waitlist_categories_lookup: BTreeMap<_, _> = data::categories::categories()
        .iter()
        .map(|cat| (&cat.id, &cat.name))
        .collect();

    let records = sqlx::query!(
        "
            SELECT
                we.id we_id,
                we.joined_at we_joined_at,
                we.account_id we_account_id,
                wef.id wef_id,
                wef.state wef_state,
                wef.category wef_category,
                wef.cached_time_in_fleet wef_cached_time_in_fleet,
                wef.review_comment wef_review_comment,
                wef.tags wef_tags,
                wef.fit_analysis wef_fit_analysis,
				wef.is_alt wef_is_alt,
                char_wef.id char_wef_id,
                char_wef.name char_wef_name,
                char_we.id char_we_id,
                char_we.name char_we_name,
                fitting.dna fitting_dna,
                fitting.hull fitting_hull,
                implant_set.implants implant_set_implants
                FROM waitlist_entry_fit wef
            JOIN waitlist_entry we ON wef.entry_id = we.id
            JOIN character char_wef ON wef.character_id = char_wef.id
            JOIN character char_we ON we.account_id = char_we.id
            JOIN fitting ON wef.fit_id = fitting.id
            JOIN implant_set ON wef.implant_set_id = implant_set.id
            ORDER BY we.id ASC, wef.id ASC
        "
    )
    .fetch_all(app.get_db())
    .await?;

    let hulls: Vec<_> = records
        .iter()
        .map(|r| r.fitting_hull)
        .collect::<BTreeSet<_>>()
        .into_iter()
        .collect();
    let hull_names = TypeDB::names_of(&hulls)?;

    let mut entries = BTreeMap::new();
    for record in records {
        let x_is_ours = record.we_account_id == account.id;

        match entries.entry(record.we_id) {
            Entry::Vacant(entry) => {
                entry.insert(
                WaitlistEntry {
                    id: record.we_id,
                    fits: Vec::new(),
                    character: if x_is_ours || account.access.contains("waitlist-view") {
                        Some(Character {
                            id: record.char_we_id,
                            name: record.char_we_name.clone(),
                            corporation_id: None,
                        })
                    } else {
                        None
                    },
                    joined_at: record.we_joined_at,
                    can_remove: x_is_ours || account.access.contains("waitlist-manage"),
                    fleet_time: get_time_in_fleet(app.get_db(), record.char_we_id).await?
                });
            },
            Entry::Occupied(_entry) => (),
        };

        let entry = entries.get_mut(&record.we_id).unwrap();

        let tags = vec![];
        let mut this_fit = WaitlistEntryFit {
            id: record.wef_id,
            approved: record.wef_state == "Approved",
            state: record.wef_state,
            category: waitlist_categories_lookup
                .get(&record.wef_category)
                .unwrap()
                .to_string(),
            tags,
            hull: Hull {
                id: record.fitting_hull as TypeID,
                name: hull_names
                    .get(&record.fitting_hull)
                    .expect("Expected hull to exist")
                    .clone(),
            },
            character: None,
            hours_in_fleet: None,
            review_comment: None,
            dna: None,
            implants: None,
            fit_analysis: None,
            is_alt: record.wef_is_alt == true,
        };

        let tags = record
            .wef_tags
            .split(',')
            .into_iter()
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string());

        if x_is_ours || account.access.contains("waitlist-view") {
            this_fit.character = Some(Character {
                id: record.char_wef_id,
                name: record.char_wef_name,
                corporation_id: None,
            });
            this_fit.hours_in_fleet = Some(record.wef_cached_time_in_fleet / 3600);
            this_fit.review_comment = record.wef_review_comment;
            this_fit.tags = tags.collect();
        } else {
            this_fit.tags = tags
                .filter(|t| data::tags::public_tags().contains(t))
                .collect();
        }

        if x_is_ours
            || (account.access.contains("waitlist-view") && account.access.contains("fit-view"))
        {
            this_fit.dna = Some(record.fitting_dna);
            this_fit.implants = Some(
                record
                    .implant_set_implants
                    .split(':')
                    .filter(|s| !s.is_empty())
                    .map(|s| s.parse::<TypeID>().unwrap())
                    .collect(),
            );
            if let Some(fit_analysis) = record.wef_fit_analysis {
                this_fit.fit_analysis = rocket::serde::json::from_str(&fit_analysis).unwrap();
            }
        }

        entry.fits.push(this_fit);
    }
    Ok(Json(WaitlistResponse {
        open: true,
        categories: waitlist_categories,
        waitlist: Some(entries.into_iter().map(|(_id, entry)| entry).collect()),
    }))
}

pub fn routes() -> Vec<rocket::Route> {
    routes![fleet_waitlist]
}
