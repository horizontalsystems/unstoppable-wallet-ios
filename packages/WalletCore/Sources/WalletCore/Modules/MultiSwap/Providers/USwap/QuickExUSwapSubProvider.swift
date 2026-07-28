import Foundation
import MarketKit

public final class QuickExUSwapSubProvider: DefaultUSwapSubProvider {
    public override func validateTrustedProvider(tokenIn: Token, amountIn: Decimal) async throws -> Bool? {
        let addresses = await DestinationHelper.sourceAddresses(
            token: tokenIn,
            amountIn: amountIn,
            destinationAddress: nil
        )

        guard !addresses.isEmpty else {
            return true
        }

        do {
            return try await api.checkAddresses(
                USwapMultiSwapApi.CheckAddressesRequest(addresses: addresses)
            )
        } catch {
            print("Error: \(error)")
            throw error
        }
    }
}
