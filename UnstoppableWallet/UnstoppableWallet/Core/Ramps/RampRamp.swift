import Foundation
import MarketKit

class RampRamp {}

extension RampRamp: IRamp {
    var title: String {
        "Ramp"
    }

    var logoUrl: String {
        ""
    }

    func quote(token _: Token, fiatAmount _: Decimal, currencyCode _: String) async throws -> RampQuote? {
        nil
    }
}
