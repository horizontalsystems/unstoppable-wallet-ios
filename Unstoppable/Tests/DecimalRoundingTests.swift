import Foundation
import Testing
@testable import WalletCore

struct DecimalRoundingTests {
    @Test func roundsPositiveValuesDownToRequestedPrecision() {
        #expect(Decimal(string: "1.2341")?.roundedDown(decimal: 2) == Decimal(string: "1.23"))
    }

    @Test func preservesExactValuesAtRequestedPrecision() {
        #expect(Decimal(string: "1.23")?.roundedDown(decimal: 2) == Decimal(string: "1.23"))
    }

    @Test func roundsSubUnitValueDownToZeroAtZeroDecimals() {
        #expect(Decimal(string: "0.333")?.roundedDown(decimal: 0) == 0)
    }
}
