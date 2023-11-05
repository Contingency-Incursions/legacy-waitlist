use crate::{
    app::Application,
    core::sse::{Event, SSEError},
};
use serde::Serialize;

#[derive(Debug, Serialize)]
struct Message {
    message: &'static str,
}

pub async fn notify_waitlist_update(app: &Application) -> Result<(), SSEError> {
    app.sse_client
        .submit(vec![Event::new_json(
            "waitlist",
            "waitlist_update",
            "waitlist_update",
        )])
        .await?;
    Ok(())
}

pub async fn notify_waitlist_update_and_xup(
    app: &Application,
) -> Result<(), SSEError> {
    app.sse_client
        .submit(vec![Event::new_json(
            "waitlist",
            "waitlist_update",
            "waitlist_update",
        )])
        .await?;

    if let Ok(fleets) = sqlx::query!("SELECT boss_id FROM fleet")
        .fetch_all(app.get_db())
        .await
    {
        for fleet in fleets {
            app.sse_client
                .submit(vec![Event::new_json(
                    &format!("account;{}", fleet.boss_id),
                    "notification",
                    &Message {
                        message: "New x-up in waitlist",
                    },
                )])
                .await?;
        }
    }
    Ok(())
}
