use chrono::{DateTime, NaiveDate, Utc};

/// Parse a BCP-47 locale string (e.g., "ja-JP", "en-US", "de-DE") into a
/// `chrono::Locale`. Falls back to `en_US` on unknown input with a warn log.
pub fn parse_locale(s: &str) -> chrono::Locale {
    // Normalise BCP-47 separator: "ja-JP" → "ja_JP".
    let normalised = s.replace('-', "_");
    match chrono::Locale::try_from(normalised.as_str()) {
        Ok(loc) => loc,
        Err(_) => {
            tracing::warn!("unknown locale '{}'; falling back to en_US", s);
            chrono::Locale::en_US
        }
    }
}

/// Format a UTC date-time for display using the given locale.
pub fn format_date(dt: DateTime<Utc>, locale: chrono::Locale) -> String {
    dt.format_localized("%x", locale).to_string()
}

/// Format a `NaiveDate` for display using the given locale.
pub fn format_naive_date(d: NaiveDate, locale: chrono::Locale) -> String {
    d.format_localized("%x", locale).to_string()
}

/// Format a week label in "YYYY-WW" (SQLite `%W` semantics) for display.
///
/// Tries to parse the label and produce a localized "Week of …" string.
/// Falls back to the raw label if parsing fails.
pub fn format_week_label(label: &str, locale: chrono::Locale) -> String {
    // Labels are "YYYY-WW" (ISO week number, 00-53).
    let parts: Vec<&str> = label.splitn(2, '-').collect();
    if parts.len() == 2
        && let (Ok(year), Ok(week)) = (parts[0].parse::<i32>(), parts[1].parse::<u32>())
    {
        // Week 0 in SQLite %W = days before first Monday; map to week 1 start.
        let effective_week = week.max(1);
        // NaiveDate::from_isoywd_opt uses ISO week (Mon-based).
        if let Some(d) = NaiveDate::from_isoywd_opt(year, effective_week, chrono::Weekday::Mon) {
            let formatted = d.format_localized("%x", locale).to_string();
            return format!("{label} (w/o {formatted})");
        }
    }
    label.to_string()
}

/// Resolve the effective locale from the priority chain:
/// 1. CLI flag (`cli_override`) — highest priority.
/// 2. Config `[display] locale`.
/// 3. `$LANG` env var (normalised, e.g. "ja_JP.UTF-8" → "ja-JP").
/// 4. "en-US" default.
pub fn resolve_locale(cli_override: Option<&str>, config_locale: Option<&str>) -> chrono::Locale {
    if let Some(s) = cli_override {
        return parse_locale(s);
    }
    if let Some(s) = config_locale {
        return parse_locale(s);
    }
    if let Ok(lang) = std::env::var("LANG") {
        // "ja_JP.UTF-8" → "ja_JP" → parse
        let bare = lang.split('.').next().unwrap_or(&lang);
        if bare.len() >= 2 && bare != "C" && bare != "POSIX" {
            // Only treat it as a locale if it looks like "xx" or "xx_XX".
            if chrono::Locale::try_from(bare).is_ok() {
                return parse_locale(bare);
            }
        }
    }
    chrono::Locale::en_US
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    #[test]
    fn parse_locale_ja_jp() {
        let loc = parse_locale("ja-JP");
        assert_eq!(loc, chrono::Locale::ja_JP);
    }

    #[test]
    fn parse_locale_garbage_falls_back() {
        // "garbage" is not a valid locale; should fall back gracefully.
        let loc = parse_locale("garbage");
        assert_eq!(loc, chrono::Locale::en_US);
    }

    #[test]
    fn format_date_en_us_contains_year() {
        let dt = Utc.with_ymd_and_hms(2026, 4, 18, 0, 0, 0).unwrap();
        let s = format_date(dt, chrono::Locale::en_US);
        assert!(s.contains("2026"), "expected 2026 in '{s}'");
    }

    #[test]
    fn format_date_ja_jp_contains_cjk_era_or_digits() {
        let dt = Utc.with_ymd_and_hms(2026, 4, 18, 0, 0, 0).unwrap();
        let s = format_date(dt, chrono::Locale::ja_JP);
        // ja_JP %x typically contains "月" (month) or at least digits.
        assert!(
            s.contains('月') || s.contains("2026") || s.contains("04"),
            "unexpected ja_JP date string: '{s}'"
        );
    }

    #[test]
    fn resolve_locale_cli_wins() {
        let loc = resolve_locale(Some("ja-JP"), Some("de-DE"));
        assert_eq!(loc, chrono::Locale::ja_JP);
    }

    #[test]
    fn resolve_locale_config_wins_over_default() {
        // No CLI flag; config has de_DE.
        let loc = resolve_locale(None, Some("de-DE"));
        assert_eq!(loc, chrono::Locale::de_DE);
    }

    #[test]
    fn format_week_label_passthrough_on_bad_input() {
        let s = format_week_label("not-a-week", chrono::Locale::en_US);
        assert_eq!(s, "not-a-week");
    }

    #[test]
    fn format_week_label_en_us() {
        // Week 16 of 2026 — should produce a label containing the year.
        let s = format_week_label("2026-16", chrono::Locale::en_US);
        assert!(
            s.starts_with("2026-16"),
            "label should start with '2026-16', got '{s}'"
        );
        assert!(s.contains("2026"), "label should contain year, got '{s}'");
    }
}
