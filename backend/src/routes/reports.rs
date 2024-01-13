use crate::{app::Application, core::auth::AuthenticatedAccount, util::madness::Madness};

use bigdecimal::BigDecimal;
use rocket::serde::json::Json;
use serde::Serialize;

#[derive(Debug, Serialize)]
struct ReportRow {
    id: i64,
    character_id: i64,
    name: String,
    role: Option<String>,
    seconds_last_month: Option<BigDecimal>,
    last_seen: Option<i64>,
}

#[get("/api/reports")]
async fn get_reports(
    account: AuthenticatedAccount,
    app: &rocket::State<Application>,
) -> Result<Json<Vec<ReportRow>>, Madness> {
    account.require_access("reports-view")?;

    let activity = sqlx::query_as!(
        ReportRow,
        "SELECT
        c.id AS \"id!\",
        c.id AS \"character_id!\",
        c.name AS \"name!\",
        'Fleet Boss' AS role,
        MAX(fa.last_seen) AS \"last_seen\",
        SUM(fa.last_seen - fa.first_seen) AS \"seconds_last_month\"
        FROM character AS c JOIN \"admin\" AS a on a.character_id = c.id
        LEFT JOIN fleet_activity AS fa ON fa.character_id = c.id AND fa.is_boss = 'true' AND (fa.last_seen - fa.first_seen) > 300
        GROUP BY
        c.id,
        c.name UNION SELECT -1 * c.id AS \"id!\",
        c.id AS \"character_id!\",
        c.name AS \"name!\",
        'Logi' AS role,
        MAX(fa.last_seen) AS \"last_seen\",
        SUM(fa.last_seen - fa.first_seen) AS \"seconds_last_month\"
        FROM character AS c JOIN badge_assignment AS ba ON ba.characterId = c.id JOIN badge AS b ON b.id = ba.badgeID AND b.name = 'LOGI'
        LEFT JOIN fleet_activity AS fa ON fa.character_id = c.id AND (fa.hull=$1 OR fa.hull=$2) AND (fa.last_seen - fa.first_seen) > 300
        GROUP BY c.id, c.name",
        type_id!("Nestor"),
        type_id!("Oneiros"),
    )
    .fetch_all(app.get_db())
    .await?;

    Ok(Json(activity))
}

pub fn routes() -> Vec<rocket::Route> {
    routes![get_reports]
}
