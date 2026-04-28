//! Cap-estimator for opaque subscription windows.
//!
//! Anthropic and OpenAI publish window utilization (`used_percent`) but never
//! the absolute token cap, so we invert: cap ≈ observed_tokens / used_percent.
//! Confidence falls off linearly with utilization, and we refuse to emit a
//! number below 5% utilization (where the inversion is dominated by noise).

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct EstimatedCap {
    pub estimated_cap_tokens: i64,
    pub confidence: f64,
}

/// Returns `None` when input is too noisy for a meaningful estimate
/// (utilization < 5%, observed tokens ≤ 0, or non-finite inputs).
///
/// Otherwise returns a derived cap with a confidence in `[0.0, 1.0]`:
/// - 5–30% utilization: confidence ramps linearly from 0.16 → 1.0
/// - 30–99.5%: confidence stays at 1.0
/// - ≥ 99.5%: confidence drops to 0.5 (window is clipping; cap is a lower bound)
pub fn estimate_window_cap(used_percent: f64, observed_tokens: i64) -> Option<EstimatedCap> {
    if !used_percent.is_finite() || used_percent < 5.0 || observed_tokens <= 0 {
        return None;
    }
    let used_percent = used_percent.min(100.0);
    let cap = (observed_tokens as f64 / used_percent * 100.0).round();
    if !cap.is_finite() || cap <= 0.0 {
        return None;
    }
    let confidence = if used_percent >= 99.5 {
        0.5
    } else {
        (used_percent / 30.0).clamp(0.16, 1.0)
    };
    Some(EstimatedCap {
        estimated_cap_tokens: cap as i64,
        confidence,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn returns_none_for_low_utilization() {
        assert_eq!(estimate_window_cap(0.0, 100), None);
        assert_eq!(estimate_window_cap(4.9, 1_000_000), None);
    }

    #[test]
    fn returns_none_for_zero_observed() {
        assert_eq!(estimate_window_cap(50.0, 0), None);
        assert_eq!(estimate_window_cap(50.0, -10), None);
    }

    #[test]
    fn returns_none_for_non_finite() {
        assert_eq!(estimate_window_cap(f64::NAN, 1000), None);
        assert_eq!(estimate_window_cap(f64::INFINITY, 1000), None);
    }

    #[test]
    fn inverts_at_mid_utilization() {
        let cap = estimate_window_cap(50.0, 50_000).unwrap();
        assert_eq!(cap.estimated_cap_tokens, 100_000);
        assert!((cap.confidence - 1.0).abs() < 1e-6);
    }

    #[test]
    fn confidence_ramps_at_low_utilization() {
        let cap = estimate_window_cap(10.0, 5_000).unwrap();
        assert_eq!(cap.estimated_cap_tokens, 50_000);
        // 10 / 30 ≈ 0.333
        assert!((cap.confidence - 0.333).abs() < 0.01);
    }

    #[test]
    fn confidence_drops_when_clipping() {
        let cap = estimate_window_cap(99.9, 99_900).unwrap();
        assert_eq!(cap.confidence, 0.5);
        // cap ≈ 99_900 / 99.9 * 100 = 100_000
        assert!((cap.estimated_cap_tokens - 100_000).abs() <= 1);
    }

    #[test]
    fn clamps_used_percent_above_100() {
        // Some providers report >100% briefly; we treat as 100% for the
        // inversion to avoid pathologically small caps.
        let cap = estimate_window_cap(120.0, 100_000).unwrap();
        assert_eq!(cap.estimated_cap_tokens, 100_000);
    }

    #[test]
    fn confidence_floor_at_threshold() {
        let cap = estimate_window_cap(5.0, 1_000).unwrap();
        // 5 / 30 ≈ 0.167, above 0.16 floor
        assert!(cap.confidence >= 0.16);
        assert!(cap.confidence < 0.2);
    }
}
