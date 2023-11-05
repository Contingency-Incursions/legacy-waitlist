mod actions;
mod configure;
mod comp;
mod notify;
mod settings;
mod waitlist;

pub fn routes() -> Vec<rocket::Route> {
    [
        actions::routes(),
        configure::routes(),
        comp::routes(),
        settings::routes(),
        waitlist::routes()
    ]
    .concat()
}
