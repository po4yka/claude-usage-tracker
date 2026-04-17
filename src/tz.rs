/// Timezone parameters sent by the client on aggregation requests.
///
/// The client should send:
///   `tz_offset_min = new Date().getTimezoneOffset() * -1`
///   `week_starts_on = 0` (Sun) .. `6` (Sat)
///
/// Missing params default to UTC (preserves existing behaviour).
#[derive(Debug, Clone, Copy, serde::Deserialize, Default)]
pub struct TzParams {
    pub tz_offset_min: Option<i32>,
    // Week start is plumbed for future use; endpoints will opt in as phases land.
    #[allow(dead_code)]
    pub week_starts_on: Option<u8>,
}

impl TzParams {
    /// Clamp the timezone offset to the legitimate IANA range ±840 minutes (±14 h).
    pub fn normalized_offset_min(&self) -> i32 {
        match self.tz_offset_min {
            None => 0,
            Some(v) => v.clamp(-840, 840),
        }
    }

    /// Returns the SQL `day` expression for the given timestamp column.
    ///
    /// When the offset is zero or absent the expression is the cheap
    /// `substr(col, 1, 10)`.  When a non-zero offset is present the
    /// expression shifts the ISO-8601 string with SQLite's `datetime()`
    /// and a bound parameter `?` that the caller must bind to the value
    /// returned by [`TzParams::offset_sql_param`].
    ///
    /// Example (offset = 120):
    ///   expression  → `"substr(datetime(t.timestamp, ?), 1, 10)"`
    ///   bound param → `"+120 minutes"`
    pub fn sql_day_expr(&self, ts_column: &str) -> String {
        if self.normalized_offset_min() == 0 {
            format!("substr({ts_column}, 1, 10)")
        } else {
            format!("substr(datetime({ts_column}, ?), 1, 10)")
        }
    }

    /// The SQL bound parameter value that accompanies `sql_day_expr` when the
    /// offset is non-zero.  Returns `None` when no parameter is needed.
    pub fn offset_sql_param(&self) -> Option<String> {
        let offset = self.normalized_offset_min();
        if offset == 0 {
            None
        } else {
            Some(format!("{:+} minutes", offset))
        }
    }

    /// Week-start day of week: 0 = Sunday … 6 = Saturday.
    /// Out-of-range values (> 6) are clamped to 0 (Sunday).
    /// Plumbed for future use; endpoints will opt in as phases land.
    #[allow(dead_code)]
    pub fn normalized_week_starts_on(&self) -> u8 {
        match self.week_starts_on {
            Some(v) if v <= 6 => v,
            _ => 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::TzParams;

    fn params(offset: Option<i32>, wso: Option<u8>) -> TzParams {
        TzParams {
            tz_offset_min: offset,
            week_starts_on: wso,
        }
    }

    // --- normalized_offset_min ---

    #[test]
    fn offset_none_is_zero() {
        assert_eq!(params(None, None).normalized_offset_min(), 0);
    }

    #[test]
    fn offset_within_range_unchanged() {
        assert_eq!(params(Some(330), None).normalized_offset_min(), 330);
        assert_eq!(params(Some(-300), None).normalized_offset_min(), -300);
    }

    #[test]
    fn offset_clamped_positive_overflow() {
        assert_eq!(params(Some(3600), None).normalized_offset_min(), 840);
    }

    #[test]
    fn offset_clamped_negative_overflow() {
        assert_eq!(params(Some(-3600), None).normalized_offset_min(), -840);
    }

    #[test]
    fn offset_exact_boundary_preserved() {
        assert_eq!(params(Some(840), None).normalized_offset_min(), 840);
        assert_eq!(params(Some(-840), None).normalized_offset_min(), -840);
    }

    // --- sql_day_expr ---

    #[test]
    fn sql_expr_no_offset_is_simple_substr() {
        let expr = params(None, None).sql_day_expr("t.timestamp");
        assert_eq!(expr, "substr(t.timestamp, 1, 10)");
    }

    #[test]
    fn sql_expr_zero_offset_is_simple_substr() {
        let expr = params(Some(0), None).sql_day_expr("t.timestamp");
        assert_eq!(expr, "substr(t.timestamp, 1, 10)");
    }

    #[test]
    fn sql_expr_nonzero_offset_uses_datetime_placeholder() {
        let expr = params(Some(120), None).sql_day_expr("t.timestamp");
        assert_eq!(expr, "substr(datetime(t.timestamp, ?), 1, 10)");
    }

    #[test]
    fn sql_expr_negative_offset_uses_datetime_placeholder() {
        let expr = params(Some(-480), None).sql_day_expr("t.timestamp");
        assert_eq!(expr, "substr(datetime(t.timestamp, ?), 1, 10)");
    }

    // --- offset_sql_param ---

    #[test]
    fn param_none_when_no_offset() {
        assert_eq!(params(None, None).offset_sql_param(), None);
    }

    #[test]
    fn param_none_when_zero_offset() {
        assert_eq!(params(Some(0), None).offset_sql_param(), None);
    }

    #[test]
    fn param_positive_offset_formatted() {
        assert_eq!(
            params(Some(120), None).offset_sql_param(),
            Some("+120 minutes".to_string())
        );
    }

    #[test]
    fn param_negative_offset_has_leading_minus() {
        assert_eq!(
            params(Some(-480), None).offset_sql_param(),
            Some("-480 minutes".to_string())
        );
    }

    #[test]
    fn param_clamped_value_used_for_param() {
        // 3600 clamps to 840
        assert_eq!(
            params(Some(3600), None).offset_sql_param(),
            Some("+840 minutes".to_string())
        );
    }

    // --- normalized_week_starts_on ---

    #[test]
    fn week_starts_on_none_defaults_to_sunday() {
        assert_eq!(params(None, None).normalized_week_starts_on(), 0);
    }

    #[test]
    fn week_starts_on_valid_range() {
        for dow in 0u8..=6 {
            assert_eq!(params(None, Some(dow)).normalized_week_starts_on(), dow);
        }
    }

    #[test]
    fn week_starts_on_out_of_range_clamps_to_sunday() {
        assert_eq!(params(None, Some(7)).normalized_week_starts_on(), 0);
        assert_eq!(params(None, Some(255)).normalized_week_starts_on(), 0);
    }

    // --- default produces UTC-equivalent expression ---

    #[test]
    fn default_params_produce_utc_expression() {
        let tz = TzParams::default();
        assert_eq!(tz.normalized_offset_min(), 0);
        assert_eq!(tz.offset_sql_param(), None);
        assert_eq!(tz.sql_day_expr("timestamp"), "substr(timestamp, 1, 10)");
        assert_eq!(tz.normalized_week_starts_on(), 0);
    }
}
