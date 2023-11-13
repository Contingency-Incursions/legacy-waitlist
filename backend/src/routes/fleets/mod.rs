mod actions;
mod configure;
mod comp;
mod notify;
mod settings;
mod waitlist;
mod historic;

pub fn routes() -> Vec<rocket::Route> {
    [
        actions::routes(),
        configure::routes(),
        comp::routes(),
        settings::routes(),
        waitlist::routes(),
        historic::routes()
    ]
    .concat()
}
