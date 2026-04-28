//! Cap-estimator for opaque subscription windows.
//!
//! Anthropic and OpenAI publish window utilization (`used_percent`) but never
//! the absolute token cap, so we invert: cap ≈ observed_tokens / used_percent.
//! Confidence falls off linearly with utilization, and we refuse to emit a
//! number below 5% utilization (where the inversion is dominated by noise).
//!
//! `smooth_with_history` layers a confidence-weighted EMA on top of the raw
//! inversion so individual noisy snapshots don't dominate the displayed cap.

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

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CapShift {
    Increase,
    Decrease,
}

impl CapShift {
    pub fn as_str(self) -> &'static str {
        match self {
            CapShift::Increase => "increase",
            CapShift::Decrease => "decrease",
        }
    }
}

/// Output of [`smooth_with_history`]. Carries both the raw current
/// observation and a smoothed estimate so the UI can show whichever it
/// prefers (typically the smoothed value, with the raw one feeding the
/// history chart).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct SmoothedEstimate {
    pub current_cap_tokens: i64,
    pub smoothed_cap_tokens: i64,
    pub confidence: f64,
    pub sample_count: u32,
    pub cap_shift: Option<CapShift>,
}

const SMOOTH_DECAY: f64 = 0.85;
const CONFIDENCE_FLOOR: f64 = 0.16;
const CAP_SHIFT_THRESHOLD: f64 = 0.20;
const CAP_SHIFT_MIN_HISTORY: usize = 6;
const CAP_SHIFT_MIN_CONFIDENCE: f64 = 0.30;

/// Confidence-weighted EMA over the trailing history plus the current
/// observation, with a small cap-shift detector that flags genuine policy
/// changes (≥ ±20% delta vs the history-only baseline) when both sides have
/// enough confidence to be trustworthy.
///
/// `history` must be ordered most-recent first. Rows with confidence below
/// [`CONFIDENCE_FLOOR`] are skipped (those snapshots were already considered
/// noisy by the estimator). When the trailing history is empty or fully
/// filtered out, the smoothed value falls back to the current observation
/// and `cap_shift` is `None`.
pub fn smooth_with_history(current: EstimatedCap, history: &[(f64, i64)]) -> SmoothedEstimate {
    let trailing: Vec<(usize, f64, i64)> = history
        .iter()
        .enumerate()
        .filter(|(_, (conf, _))| conf.is_finite() && *conf >= CONFIDENCE_FLOOR)
        .map(|(i, (conf, cap))| (i, *conf, *cap))
        .collect();

    fn ema(rows: &[(usize, f64, i64)]) -> Option<f64> {
        let mut num = 0.0;
        let mut den = 0.0;
        for &(age_index, conf, cap) in rows {
            let w = conf * SMOOTH_DECAY.powi(age_index as i32);
            num += w * (cap as f64);
            den += w;
        }
        if den > 0.0 { Some(num / den) } else { None }
    }

    let history_ema = ema(&trailing);

    let combined_smoothed = {
        let mut num = current.confidence * (current.estimated_cap_tokens as f64);
        let mut den = current.confidence;
        for &(age_index, conf, cap) in &trailing {
            let w = conf * SMOOTH_DECAY.powi((age_index + 1) as i32);
            num += w * (cap as f64);
            den += w;
        }
        if den > 0.0 {
            (num / den).round() as i64
        } else {
            current.estimated_cap_tokens
        }
    };

    let sample_count = (trailing.len() + 1) as u32;

    let cap_shift = match history_ema {
        Some(baseline)
            if baseline > 0.0
                && trailing
                    .iter()
                    .filter(|(_, c, _)| *c >= CAP_SHIFT_MIN_CONFIDENCE)
                    .count()
                    >= CAP_SHIFT_MIN_HISTORY
                && current.confidence >= CAP_SHIFT_MIN_CONFIDENCE =>
        {
            let delta = (current.estimated_cap_tokens as f64 - baseline) / baseline;
            if delta > CAP_SHIFT_THRESHOLD {
                Some(CapShift::Increase)
            } else if delta < -CAP_SHIFT_THRESHOLD {
                Some(CapShift::Decrease)
            } else {
                None
            }
        }
        _ => None,
    };

    SmoothedEstimate {
        current_cap_tokens: current.estimated_cap_tokens,
        smoothed_cap_tokens: combined_smoothed,
        confidence: current.confidence,
        sample_count,
        cap_shift,
    }
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

    fn cap(tokens: i64, conf: f64) -> EstimatedCap {
        EstimatedCap {
            estimated_cap_tokens: tokens,
            confidence: conf,
        }
    }

    #[test]
    fn smooth_falls_back_to_current_with_no_history() {
        let s = smooth_with_history(cap(100_000, 1.0), &[]);
        assert_eq!(s.smoothed_cap_tokens, 100_000);
        assert_eq!(s.current_cap_tokens, 100_000);
        assert_eq!(s.sample_count, 1);
        assert_eq!(s.cap_shift, None);
    }

    #[test]
    fn smooth_falls_back_when_history_below_floor() {
        let history = vec![(0.05, 999_999); 10];
        let s = smooth_with_history(cap(100_000, 1.0), &history);
        assert_eq!(s.smoothed_cap_tokens, 100_000);
        assert_eq!(s.sample_count, 1);
    }

    #[test]
    fn smooth_dampens_outlier() {
        let history: Vec<(f64, i64)> = (0..12).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(200_000, 1.0), &history);
        assert!(
            s.smoothed_cap_tokens < 130_000,
            "expected damped < 130K, got {}",
            s.smoothed_cap_tokens
        );
        assert!(s.smoothed_cap_tokens > 100_000);
        assert_eq!(s.sample_count, 13);
    }

    #[test]
    fn smooth_converges_on_identical_history() {
        let history: Vec<(f64, i64)> = (0..24).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(100_000, 1.0), &history);
        assert_eq!(s.smoothed_cap_tokens, 100_000);
        assert_eq!(s.sample_count, 25);
    }

    #[test]
    fn cap_shift_increase_fires_above_threshold() {
        let history: Vec<(f64, i64)> = (0..12).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(130_000, 1.0), &history);
        assert_eq!(s.cap_shift, Some(CapShift::Increase));
    }

    #[test]
    fn cap_shift_decrease_fires_below_threshold() {
        let history: Vec<(f64, i64)> = (0..12).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(75_000, 1.0), &history);
        assert_eq!(s.cap_shift, Some(CapShift::Decrease));
    }

    #[test]
    fn cap_shift_none_within_tolerance() {
        let history: Vec<(f64, i64)> = (0..12).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(105_000, 1.0), &history);
        assert_eq!(s.cap_shift, None);
    }

    #[test]
    fn cap_shift_none_with_short_history() {
        let history: Vec<(f64, i64)> = (0..3).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(200_000, 1.0), &history);
        assert_eq!(s.cap_shift, None);
    }

    #[test]
    fn cap_shift_none_when_current_low_confidence() {
        let history: Vec<(f64, i64)> = (0..12).map(|_| (1.0, 100_000)).collect();
        let s = smooth_with_history(cap(200_000, 0.20), &history);
        assert_eq!(s.cap_shift, None);
    }
}
