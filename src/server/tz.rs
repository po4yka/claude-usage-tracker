/// Re-export `TzParams` from the crate-level `tz` module so that
/// callers can use either `crate::tz::TzParams` or
/// `crate::server::tz::TzParams` — whichever is more natural in context.
/// Having the canonical definition at crate root avoids a circular
/// dependency between `scanner::db` and `server`.
#[allow(unused_imports)]
pub use crate::tz::TzParams;
