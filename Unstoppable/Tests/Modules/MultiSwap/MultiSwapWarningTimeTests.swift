import Foundation
import Testing
@testable import Unstoppable
@testable import WalletCore

struct MultiSwapWarningTimeTests {
    private typealias VM = MultiSwapViewModel

    // MARK: - Spec cases (swap_time_spec_v2.docx)

    @Test func specCase1_allFast_outlierBelowThreshold_silent() {
        // baseline 1m30s, outlier 6m. 6m ≤ 30m → silent.
        #expect(VM.warningTime(for: 90, baseline: 90) == nil)
        #expect(VM.warningTime(for: 120, baseline: 90) == nil)
        #expect(VM.warningTime(for: 180, baseline: 90) == nil)
        #expect(VM.warningTime(for: 360, baseline: 90) == nil)
    }

    @Test func specCase2_allSlow_ratioBelowTwo_silent() {
        // baseline 45m, all ratios < 2 → silent across the board.
        #expect(VM.warningTime(for: 2700, baseline: 2700) == nil)
        #expect(VM.warningTime(for: 3300, baseline: 2700) == nil) // 55m, ratio 1.22
        #expect(VM.warningTime(for: 4200, baseline: 2700) == nil) // 1h10m, ratio 1.56
        #expect(VM.warningTime(for: 4800, baseline: 2700) == nil) // 1h20m, ratio 1.78
    }

    @Test func specCase3_realAnomaly_twoOutliersAttention() {
        // baseline 20m. 45m and 1h10m trigger both conditions.
        #expect(VM.warningTime(for: 1200, baseline: 1200) == nil) // baseline itself
        #expect(VM.warningTime(for: 1500, baseline: 1200) == nil) // 25m ≤ 30m
        #expect(VM.warningTime(for: 2700, baseline: 1200) == 2700) // 45m, ratio 2.25
        #expect(VM.warningTime(for: 4200, baseline: 1200) == 4200) // 1h10m, ratio 3.5
    }

    @Test func specCase4_singleProvider_absoluteThresholdOnly() {
        // Single provider: baseline=nil → ratio not applicable, only absolute threshold.
        #expect(VM.warningTime(for: 1080, baseline: nil) == nil) // 18m
        #expect(VM.warningTime(for: 2460, baseline: nil) == 2460) // 41m
        #expect(VM.warningTime(for: 5400, baseline: nil) == 5400) // 1h30m
    }

    @Test func specCase5_boundaryAt30Minutes() {
        // baseline 15m. Near at 32m is the first to trip both conditions.
        #expect(VM.warningTime(for: 900, baseline: 900) == nil) // 15m
        #expect(VM.warningTime(for: 1200, baseline: 900) == nil) // 20m
        #expect(VM.warningTime(for: 1740, baseline: 900) == nil) // 29m
        #expect(VM.warningTime(for: 1920, baseline: 900) == 1920) // 32m, ratio 2.13
    }

    // MARK: - Edge cases

    @Test func edge_timeNil_returnsNil() {
        #expect(VM.warningTime(for: nil, baseline: 900) == nil)
    }

    @Test func edge_timeZero_returnsNil() {
        #expect(VM.warningTime(for: 0, baseline: 900) == nil)
    }

    @Test func edge_baselineZero_collapsesToAbsoluteThreshold() {
        // baseline 0 is treated as missing → fall back to absolute threshold rule.
        #expect(VM.warningTime(for: 4000, baseline: 0) == 4000)
        #expect(VM.warningTime(for: 100, baseline: 0) == nil)
    }

    @Test func edge_baselineNil_collapsesToAbsoluteThreshold() {
        #expect(VM.warningTime(for: 4000, baseline: nil) == 4000)
        #expect(VM.warningTime(for: 100, baseline: nil) == nil)
    }

    @Test func edge_thresholdExactly30Minutes_silent() {
        // 30m exactly does not trip — spec says strictly greater than 30m.
        #expect(VM.warningTime(for: 1800, baseline: nil) == nil)
        #expect(VM.warningTime(for: 1800, baseline: 600) == nil)
    }

    // MARK: - Time value (precise vs interval, #7095)

    @Test func precise_rendersApproximateAndJudgesCenter() {
        let neutralState = VM.timeState(for: 600, precise: true, baseline: nil)
        #expect(neutralState == .neutral(.approximate(600)))

        let attentionState = VM.timeState(for: 2460, precise: true, baseline: nil)
        #expect(attentionState == .attention(.approximate(2460)))
    }

    @Test func imprecise_rendersQuarterRangeAroundEstimate() {
        // X = 48m → 36m–1h
        let state = VM.timeState(for: 2880, precise: false, baseline: nil)
        #expect(state == .attention(.range(min: 2160, max: 3600)))
    }

    @Test func imprecise_upperBoundTripsThresholdWhereCenterWouldNot() {
        // X = 25m: center is under 30m, but X·1.25 = 31.25m crosses it.
        let imprecise = VM.timeState(for: 1500, precise: false, baseline: nil)
        #expect(imprecise == .attention(.range(min: 1125, max: 1875)))

        let precise = VM.timeState(for: 1500, precise: true, baseline: nil)
        #expect(precise == .neutral(.approximate(1500)))
    }

    @Test func imprecise_upperBoundJudgedAgainstBaselineRatio() {
        // baseline 20m, X = 20m: upper bound 25m ≤ 30m → neutral despite ratio context.
        let state = VM.timeState(for: 1200, precise: false, baseline: 1200)
        #expect(state == .neutral(.range(min: 900, max: 1500)))
    }

    @Test func timeState_nilOrZero_returnsNil() {
        #expect(VM.timeState(for: nil, precise: false, baseline: nil) == nil)
        #expect(VM.timeState(for: 0, precise: true, baseline: 900) == nil)
    }

    // MARK: - Formatting (Android parity)

    @Test func format_approximate_prefixedWithTilde() {
        let string = MultiSwapQuotesView.string(time: .approximate(600))
        #expect(string.hasPrefix("~"))
        #expect(!string.contains("-"))
    }

    @Test func format_range_boundsRoundedToMinutesAndDashed() {
        // 48m → 36m-1h
        let string = MultiSwapQuotesView.string(time: .range(min: 2160, max: 3600))
        #expect(string.contains("-"))
        #expect(!string.hasPrefix("~"))
    }

    @Test func format_rangeCollapsedAfterRounding_rendersAsApproximate() {
        // 100s and 110s both round to 2m → single approximate value.
        let string = MultiSwapQuotesView.string(time: .range(min: 100, max: 110))
        #expect(string.hasPrefix("~"))
        #expect(!string.contains("-"))
    }

    @Test func format_rangeFloorIsOneMinute() {
        // Sub-minute bounds round up to the 1m floor and collapse.
        let string = MultiSwapQuotesView.string(time: .range(min: 10, max: 20))
        #expect(string.hasPrefix("~"))
    }
}
