import Foundation
import Testing
@testable import WalletCore

struct DecimalRoundingTests {
    @Test func roundsPositiveValuesUpToRequestedPrecision() {
        #expect(Decimal(string: "1.2341")?.roundedUp(decimal: 2) == Decimal(string: "1.24"))
    }

    @Test func preservesExactValuesAtRequestedPrecision() {
        #expect(Decimal(string: "1.23")?.roundedUp(decimal: 2) == Decimal(string: "1.23"))
    }
}
