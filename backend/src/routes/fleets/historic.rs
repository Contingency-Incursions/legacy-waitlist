use rocket::serde::json::Json;
use serde::Serialize;

use crate::{app::Application, core::auth::AuthenticatedAccount, util::madness::Madness};

use serde::Deserialize;

#[derive(Debug, Serialize)]
struct HistoryResponse {
    fleets: Vec<Fleet>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
struct Fleet {
    fleet_id: i64,
    character_name: String,
    fleet_end: i64,
    fleet_time: i64,
}

#[get("/api/v2/fleets/history")]
async fn fleet_history(
    app: &rocket::State<Application>,
    account: AuthenticatedAccount,
) -> Result<Json<HistoryResponse>, Madness> {
    account.require_access("fleet-view")?;
    let res: Vec<Fleet> = sqlx::query_as(
        "select
    fleet_id,
    c.name as character_name,
    max(fa.last_seen) as fleet_end,
    CAST((max(fa.last_seen) - min(fa.first_seen)) as BIGINT) AS fleet_time
    from fleet_activity fa
    left join character c on c.id = fa.character_id
    where is_boss = true
    group by 1,2
    order by 3 desc
    limit 20;",
    )
    .fetch_all(app.get_db())
    .await?;

    Ok(Json(HistoryResponse { fleets: res }))
}

pub fn routes() -> Vec<rocket::Route> {
    routes![fleet_history]
}
