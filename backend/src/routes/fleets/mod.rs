mod actions;
mod comp;
mod configure;
mod historic;
mod notify;
mod settings;
mod waitlist;

pub fn routes() -> Vec<rocket::Route> {
    [
        actions::routes(),
        configure::routes(),
        comp::routes(),
        settings::routes(),
        waitlist::routes(),
        historic::routes(),
    ]
    .concat()
}
