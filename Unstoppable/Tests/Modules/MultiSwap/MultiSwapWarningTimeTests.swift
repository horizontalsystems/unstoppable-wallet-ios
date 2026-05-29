import Foundation
import Testing
@testable import Unstoppable

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
}
