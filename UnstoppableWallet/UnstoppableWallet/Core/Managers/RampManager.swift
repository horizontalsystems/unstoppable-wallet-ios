import Foundation
import MarketKit

class RampManager {
    let ramps: [IRamp]

    init(ramps: [IRamp]) {
        self.ramps = ramps
    }
}

extension RampManager {
    func quotes(token: Token, fiatAmount: Decimal, currencyCode: String) async -> [RampQuote] {
        await withTaskGroup(of: RampQuote?.self) { group in
            for ramp in ramps {
                group.addTask {
                    do {
                        return try await ramp.quote(token: token, fiatAmount: fiatAmount, currencyCode: currencyCode)
                    } catch {
                        return nil
                    }
                }
            }

            var results = [RampQuote]()

            for await result in group {
                if let result {
                    results.append(result)
                }
            }

            return results
        }
    }
}
