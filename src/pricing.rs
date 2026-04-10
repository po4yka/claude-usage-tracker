use std::collections::HashMap;
use std::sync::OnceLock;

pub const PRICING_VERSION: &str = "2026-04-10";
pub const PRICING_VALID_FROM: &str = "2026-04-10T00:00:00Z";
pub const COST_CONFIDENCE_HIGH: &str = "high";
pub const COST_CONFIDENCE_MEDIUM: &str = "medium";
pub const COST_CONFIDENCE_LOW: &str = "low";

#[derive(Debug, Clone, Copy)]
pub struct ModelPricing {
    pub input: f64,
    pub output: f64,
    pub cache_write: f64,
    pub cache_read: f64,
    /// If total input+output tokens exceed this threshold, tokens above it
    /// are billed at the `*_above_threshold` rates instead.
    pub threshold_tokens: Option<i64>,
    pub input_above_threshold: Option<f64>,
    pub output_above_threshold: Option<f64>,
}

#[derive(Debug, Clone)]
pub struct CostEstimate {
    pub estimated_cost_nanos: i64,
    pub pricing_version: String,
    pub pricing_model: String,
    pub cost_confidence: String,
}

static PRICING_OVERRIDES: OnceLock<HashMap<String, ModelPricing>> = OnceLock::new();

/// Install custom pricing overrides from config. Call once at startup.
pub fn set_overrides(overrides: HashMap<String, ModelPricing>) {
    let _ = PRICING_OVERRIDES.set(overrides);
}

fn get_override(model: &str) -> Option<&ModelPricing> {
    PRICING_OVERRIDES.get()?.get(model)
}

const PRICING_TABLE: &[(&str, ModelPricing)] = &[
    (
        "gpt-5.4",
        ModelPricing {
            input: 2.50,
            output: 15.0,
            cache_write: 2.50,
            cache_read: 0.25,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "gpt-5.4-mini",
        ModelPricing {
            input: 0.75,
            output: 4.50,
            cache_write: 0.75,
            cache_read: 0.075,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "gpt-5.4-nano",
        ModelPricing {
            input: 0.20,
            output: 1.25,
            cache_write: 0.20,
            cache_read: 0.02,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "gpt-5.3-codex",
        ModelPricing {
            input: 1.75,
            output: 14.0,
            cache_write: 1.75,
            cache_read: 0.175,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "claude-opus-4-6",
        ModelPricing {
            input: 15.0,
            output: 75.0,
            cache_write: 18.75,
            cache_read: 1.50,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "claude-opus-4-5",
        ModelPricing {
            input: 15.0,
            output: 75.0,
            cache_write: 18.75,
            cache_read: 1.50,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "claude-sonnet-4-6",
        ModelPricing {
            input: 3.0,
            output: 15.0,
            cache_write: 3.75,
            cache_read: 0.30,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "claude-sonnet-4-5",
        ModelPricing {
            input: 3.0,
            output: 15.0,
            cache_write: 3.75,
            cache_read: 0.30,
            threshold_tokens: Some(200_000),
            input_above_threshold: Some(6.0),
            output_above_threshold: Some(22.5),
        },
    ),
    (
        "claude-haiku-4-5",
        ModelPricing {
            input: 1.0,
            output: 5.0,
            cache_write: 1.25,
            cache_read: 0.10,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
    (
        "claude-haiku-4-6",
        ModelPricing {
            input: 1.0,
            output: 5.0,
            cache_write: 1.25,
            cache_read: 0.10,
            threshold_tokens: None,
            input_above_threshold: None,
            output_above_threshold: None,
        },
    ),
];

/// Look up pricing for a model.
/// Checks config overrides first, then built-in table (exact, prefix, substring fallback).
#[allow(dead_code)]
pub fn get_pricing(model: &str) -> Option<&ModelPricing> {
    if model.is_empty() {
        return None;
    }
    if let Some(p) = get_override(model) {
        return Some(p);
    }
    for (name, pricing) in PRICING_TABLE {
        if *name == model {
            return Some(pricing);
        }
    }
    for (name, pricing) in PRICING_TABLE {
        if model.starts_with(name) {
            return Some(pricing);
        }
    }
    let lower = model.to_lowercase();
    if lower.contains("opus") {
        return get_builtin("claude-opus-4-6");
    }
    if lower.contains("sonnet") {
        return get_builtin("claude-sonnet-4-6");
    }
    if lower.contains("haiku") {
        return get_builtin("claude-haiku-4-5");
    }
    if lower.contains("gpt-5.4-mini") {
        return get_builtin("gpt-5.4-mini");
    }
    if lower.contains("gpt-5.4-nano") {
        return get_builtin("gpt-5.4-nano");
    }
    if lower.contains("gpt-5.4") {
        return get_builtin("gpt-5.4");
    }
    if lower.contains("codex") {
        return get_builtin("gpt-5.3-codex");
    }
    None
}

enum PricingLookup<'a> {
    Borrowed {
        pricing: &'a ModelPricing,
        pricing_model: String,
        cost_confidence: &'static str,
    },
}

fn lookup_pricing(model: &str) -> Option<PricingLookup<'_>> {
    if model.is_empty() {
        return None;
    }

    if let Some(p) = get_override(model) {
        return Some(PricingLookup::Borrowed {
            pricing: p,
            pricing_model: model.to_string(),
            cost_confidence: COST_CONFIDENCE_HIGH,
        });
    }

    for (name, pricing) in PRICING_TABLE {
        if *name == model {
            return Some(PricingLookup::Borrowed {
                pricing,
                pricing_model: (*name).to_string(),
                cost_confidence: COST_CONFIDENCE_HIGH,
            });
        }
    }

    for (name, pricing) in PRICING_TABLE {
        if model.starts_with(name) {
            return Some(PricingLookup::Borrowed {
                pricing,
                pricing_model: (*name).to_string(),
                cost_confidence: COST_CONFIDENCE_HIGH,
            });
        }
    }

    let lower = model.to_lowercase();
    if lower.contains("opus") {
        return get_builtin("claude-opus-4-6").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "claude-opus-4-6".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    if lower.contains("sonnet") {
        return get_builtin("claude-sonnet-4-6").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "claude-sonnet-4-6".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    if lower.contains("haiku") {
        return get_builtin("claude-haiku-4-5").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "claude-haiku-4-5".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    if lower.contains("gpt-5.4-mini") {
        return get_builtin("gpt-5.4-mini").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "gpt-5.4-mini".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    if lower.contains("gpt-5.4-nano") {
        return get_builtin("gpt-5.4-nano").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "gpt-5.4-nano".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    if lower.contains("gpt-5.4") {
        return get_builtin("gpt-5.4").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "gpt-5.4".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    if lower.contains("codex") {
        return get_builtin("gpt-5.3-codex").map(|pricing| PricingLookup::Borrowed {
            pricing,
            pricing_model: "gpt-5.3-codex".to_string(),
            cost_confidence: COST_CONFIDENCE_MEDIUM,
        });
    }
    None
}

/// Look up only from built-in table (avoids infinite recursion in substring fallback).
fn get_builtin(model: &str) -> Option<&'static ModelPricing> {
    PRICING_TABLE
        .iter()
        .find(|(name, _)| *name == model)
        .map(|(_, p)| p)
}

/// Returns true if this model has pricing (built-in or override).
#[allow(dead_code)]
pub fn is_billable(model: &str) -> bool {
    get_pricing(model).is_some()
}

/// Calculate cost in nanos (1 dollar = 1_000_000_000 nanos) for the given token counts.
///
/// This avoids floating-point drift when summing many small costs.
/// Rate is $/MTok, so: cost_nanos = tokens * (rate / 1e6) * 1e9 = tokens * rate * 1000.
pub fn calc_cost_nanos(
    model: &str,
    input: i64,
    output: i64,
    cache_read: i64,
    cache_creation: i64,
) -> i64 {
    let Some(lookup) = lookup_pricing(model) else {
        return 0;
    };
    let p = match lookup {
        PricingLookup::Borrowed { pricing, .. } => pricing,
    };

    calc_cost_nanos_with_pricing(p, input, output, cache_read, cache_creation)
}

fn calc_cost_nanos_with_pricing(
    p: &ModelPricing,
    input: i64,
    output: i64,
    cache_read: i64,
    cache_creation: i64,
) -> i64 {
    let total_tokens = input + output;

    let (input_cost, output_cost) =
        if let (Some(threshold), Some(input_above), Some(output_above)) = (
            p.threshold_tokens,
            p.input_above_threshold,
            p.output_above_threshold,
        ) {
            if total_tokens > threshold {
                // Split each of input and output proportionally around the threshold.
                // The proportion of tokens that fall below the threshold:
                let below_ratio = threshold as f64 / total_tokens as f64;

                let input_below = (input as f64 * below_ratio) as i64;
                let input_above_count = input - input_below;
                let input_c = (input_below as f64 * p.input * 1000.0) as i64
                    + (input_above_count as f64 * input_above * 1000.0) as i64;

                let output_below = (output as f64 * below_ratio) as i64;
                let output_above_count = output - output_below;
                let output_c = (output_below as f64 * p.output * 1000.0) as i64
                    + (output_above_count as f64 * output_above * 1000.0) as i64;

                (input_c, output_c)
            } else {
                (
                    (input as f64 * p.input * 1000.0) as i64,
                    (output as f64 * p.output * 1000.0) as i64,
                )
            }
        } else {
            (
                (input as f64 * p.input * 1000.0) as i64,
                (output as f64 * p.output * 1000.0) as i64,
            )
        };

    let cache_read_cost = (cache_read as f64 * p.cache_read * 1000.0) as i64;
    let cache_write_cost = (cache_creation as f64 * p.cache_write * 1000.0) as i64;

    input_cost + output_cost + cache_read_cost + cache_write_cost
}

pub fn estimate_cost(
    model: &str,
    input: i64,
    output: i64,
    cache_read: i64,
    cache_creation: i64,
) -> CostEstimate {
    let Some(lookup) = lookup_pricing(model) else {
        return CostEstimate {
            estimated_cost_nanos: 0,
            pricing_version: PRICING_VERSION.to_string(),
            pricing_model: String::new(),
            cost_confidence: COST_CONFIDENCE_LOW.to_string(),
        };
    };

    let (pricing, pricing_model, cost_confidence) = match lookup {
        PricingLookup::Borrowed {
            pricing,
            pricing_model,
            cost_confidence,
        } => (*pricing, pricing_model, cost_confidence),
    };

    CostEstimate {
        estimated_cost_nanos: calc_cost_nanos_with_pricing(
            &pricing,
            input,
            output,
            cache_read,
            cache_creation,
        ),
        pricing_version: format!("{PRICING_VERSION}@{PRICING_VALID_FROM}"),
        pricing_model,
        cost_confidence: cost_confidence.to_string(),
    }
}

/// Calculate cost in dollars for the given token counts.
pub fn calc_cost(
    model: &str,
    input: i64,
    output: i64,
    cache_read: i64,
    cache_creation: i64,
) -> f64 {
    calc_cost_nanos(model, input, output, cache_read, cache_creation) as f64 / 1_000_000_000.0
}

/// Format a token count for display (e.g., 1.5M, 2.3K, 999).
pub fn fmt_tokens(n: i64) -> String {
    if n >= 1_000_000 {
        format!("{:.2}M", n as f64 / 1_000_000.0)
    } else if n >= 1_000 {
        format!("{:.1}K", n as f64 / 1_000.0)
    } else {
        n.to_string()
    }
}

/// Format cost for display.
pub fn fmt_cost(c: f64) -> String {
    format!("${:.4}", c)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_exact_match() {
        let p = get_pricing("claude-sonnet-4-6").unwrap();
        assert_eq!(p.input, 3.0);
        assert_eq!(p.output, 15.0);
    }

    #[test]
    fn test_all_known_models() {
        for (name, _) in PRICING_TABLE {
            assert!(get_pricing(name).is_some(), "Missing pricing for {name}");
        }
    }

    #[test]
    fn test_prefix_match() {
        let p = get_pricing("claude-sonnet-4-6-20260401").unwrap();
        assert_eq!(p.input, 3.0);
    }

    #[test]
    fn test_substring_opus() {
        let p = get_pricing("new-opus-5-model").unwrap();
        assert_eq!(p.input, 15.0);
    }

    #[test]
    fn test_substring_case_insensitive() {
        let p = get_pricing("Claude-Opus-Next").unwrap();
        assert_eq!(p.input, 15.0);
    }

    #[test]
    fn test_unknown_returns_none() {
        assert!(get_pricing("gpt-4o").is_none());
        assert!(get_pricing("").is_none());
    }

    #[test]
    fn test_calc_cost_sonnet_input() {
        let cost = calc_cost("claude-sonnet-4-6", 1_000_000, 0, 0, 0);
        assert!((cost - 3.0).abs() < 0.001);
    }

    #[test]
    fn test_calc_cost_opus_output() {
        let cost = calc_cost("claude-opus-4-6", 0, 1_000_000, 0, 0);
        assert!((cost - 75.0).abs() < 0.001);
    }

    #[test]
    fn test_calc_cost_cache_read() {
        let cost = calc_cost("claude-opus-4-6", 0, 0, 1_000_000, 0);
        assert!((cost - 1.50).abs() < 0.001);
    }

    #[test]
    fn test_calc_cost_cache_write() {
        let cost = calc_cost("claude-opus-4-6", 0, 0, 0, 1_000_000);
        assert!((cost - 18.75).abs() < 0.001);
    }

    #[test]
    fn test_calc_cost_unknown_zero() {
        assert_eq!(calc_cost("gpt-4o", 1_000_000, 500_000, 0, 0), 0.0);
    }

    #[test]
    fn test_fmt_tokens() {
        assert_eq!(fmt_tokens(1_500_000), "1.50M");
        assert_eq!(fmt_tokens(1_500), "1.5K");
        assert_eq!(fmt_tokens(999), "999");
    }

    #[test]
    fn test_fmt_cost() {
        assert_eq!(fmt_cost(3.0), "$3.0000");
    }

    #[test]
    fn test_is_billable() {
        assert!(is_billable("claude-sonnet-4-6"));
        assert!(!is_billable("gpt-4o"));
    }

    // --- Volume discount tests ---

    #[test]
    fn test_sonnet_45_has_threshold() {
        let p = get_pricing("claude-sonnet-4-5").unwrap();
        assert_eq!(p.threshold_tokens, Some(200_000));
        assert_eq!(p.input_above_threshold, Some(6.0));
        assert_eq!(p.output_above_threshold, Some(22.5));
    }

    #[test]
    fn test_sonnet_46_no_threshold() {
        let p = get_pricing("claude-sonnet-4-6").unwrap();
        assert_eq!(p.threshold_tokens, None);
    }

    #[test]
    fn test_volume_discount_below_threshold() {
        // 100K input + 50K output = 150K total, below 200K threshold
        // Should use base rates: 3.0 input, 15.0 output
        let cost = calc_cost("claude-sonnet-4-5", 100_000, 50_000, 0, 0);
        let expected = 100_000.0 * 3.0 / 1_000_000.0 + 50_000.0 * 15.0 / 1_000_000.0;
        assert!(
            (cost - expected).abs() < 0.0001,
            "Below threshold: got {cost}, expected {expected}"
        );
    }

    #[test]
    fn test_volume_discount_above_threshold() {
        // 200K input + 200K output = 400K total, above 200K threshold
        // below_ratio = 200K/400K = 0.5
        // input: 100K at $3, 100K at $6
        // output: 100K at $15, 100K at $22.5
        let cost = calc_cost("claude-sonnet-4-5", 200_000, 200_000, 0, 0);
        let expected_input = 100_000.0 * 3.0 / 1e6 + 100_000.0 * 6.0 / 1e6;
        let expected_output = 100_000.0 * 15.0 / 1e6 + 100_000.0 * 22.5 / 1e6;
        let expected = expected_input + expected_output;
        assert!(
            (cost - expected).abs() < 0.001,
            "Above threshold: got {cost}, expected {expected}"
        );
    }

    #[test]
    fn test_volume_discount_at_threshold() {
        // Exactly at threshold: 150K input + 50K output = 200K
        // Should use base rates only
        let cost = calc_cost("claude-sonnet-4-5", 150_000, 50_000, 0, 0);
        let expected = 150_000.0 * 3.0 / 1e6 + 50_000.0 * 15.0 / 1e6;
        assert!(
            (cost - expected).abs() < 0.0001,
            "At threshold: got {cost}, expected {expected}"
        );
    }

    #[test]
    fn test_no_threshold_model_unaffected() {
        // Opus has no threshold -- large token counts should use base rates
        let cost = calc_cost("claude-opus-4-6", 1_000_000, 500_000, 0, 0);
        let expected = 1_000_000.0 * 15.0 / 1e6 + 500_000.0 * 75.0 / 1e6;
        assert!(
            (cost - expected).abs() < 0.001,
            "No threshold model: got {cost}, expected {expected}"
        );
    }

    // --- Nanos precision tests ---

    #[test]
    fn test_calc_cost_nanos_basic() {
        // 1M input tokens of sonnet at $3/MTok = $3.0 = 3_000_000_000 nanos
        let nanos = calc_cost_nanos("claude-sonnet-4-6", 1_000_000, 0, 0, 0);
        assert_eq!(nanos, 3_000_000_000);
    }

    #[test]
    fn test_calc_cost_nanos_output() {
        // 1M output tokens of opus at $75/MTok = $75.0
        let nanos = calc_cost_nanos("claude-opus-4-6", 0, 1_000_000, 0, 0);
        assert_eq!(nanos, 75_000_000_000);
    }

    #[test]
    fn test_calc_cost_nanos_unknown_zero() {
        assert_eq!(calc_cost_nanos("gpt-4o", 1_000_000, 500_000, 0, 0), 0);
    }

    #[test]
    fn test_calc_cost_wraps_nanos() {
        // Verify calc_cost is consistent with calc_cost_nanos
        let nanos = calc_cost_nanos("claude-sonnet-4-6", 1_000_000, 0, 0, 0);
        let dollars = calc_cost("claude-sonnet-4-6", 1_000_000, 0, 0, 0);
        assert!((dollars - nanos as f64 / 1e9).abs() < 1e-9);
    }

    #[test]
    fn test_nanos_precision_many_small() {
        // Sum many small costs in nanos -- should be exact
        let mut total_nanos: i64 = 0;
        for _ in 0..1000 {
            total_nanos += calc_cost_nanos("claude-sonnet-4-6", 100, 50, 0, 0);
        }
        let single = calc_cost_nanos("claude-sonnet-4-6", 100_000, 50_000, 0, 0);
        assert_eq!(total_nanos, single);
    }

    #[test]
    fn test_nanos_with_cache() {
        // 1M cache_read of opus at $1.50/MTok = 1_500_000_000 nanos
        let nanos = calc_cost_nanos("claude-opus-4-6", 0, 0, 1_000_000, 0);
        assert_eq!(nanos, 1_500_000_000);
        // 1M cache_write of opus at $18.75/MTok = 18_750_000_000 nanos
        let nanos = calc_cost_nanos("claude-opus-4-6", 0, 0, 0, 1_000_000);
        assert_eq!(nanos, 18_750_000_000);
    }

    #[test]
    fn test_nanos_large_token_count() {
        // 10 billion tokens at Opus input rate ($15/MTok)
        // Cost = 10e9 * 15 / 1e6 = $150,000
        // Nanos = 150_000 * 1e9 = 150_000_000_000_000 -- within i64 range
        let nanos = calc_cost_nanos("claude-opus-4-6", 10_000_000_000, 0, 0, 0);
        assert!(nanos > 0, "Should not overflow to negative");
        let cost = calc_cost("claude-opus-4-6", 10_000_000_000, 0, 0, 0);
        assert!((cost - 150_000.0).abs() < 1.0);
    }

    #[test]
    fn test_volume_discount_output_only() {
        // Above threshold with only output tokens
        let cost_small = calc_cost("claude-sonnet-4-5", 0, 100_000, 0, 0);
        let cost_large = calc_cost("claude-sonnet-4-5", 0, 300_000, 0, 0);
        // Larger should cost more
        assert!(cost_large > cost_small);
        // Above-threshold rate is higher ($22.5 vs $15), so cost_large > 3x cost_small
        // Just verify it's positive and proportional
        assert!(cost_large > 0.0);
    }

    #[test]
    fn test_prefix_match_priority() {
        // Exact prefix match should work for versioned models
        let p = get_pricing("claude-opus-4-6-20260401").unwrap();
        assert_eq!(p.input, 15.0);
        let p2 = get_pricing("claude-sonnet-4-5-20250929").unwrap();
        assert_eq!(p2.input, 3.0);
    }
}
