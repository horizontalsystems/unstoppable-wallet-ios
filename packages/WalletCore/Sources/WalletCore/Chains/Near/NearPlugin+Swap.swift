import MarketKit

extension NearPlugin {
    func uSwapFinalQuoteBuilders(adapterManager: AdapterManager) -> [USwapFinalQuoteBuilder] {
        [USwapNearFinalQuoteBuilder(adapterManager: adapterManager)]
    }

    func swapDestinationAddress(blockchainType: BlockchainType, account: Account) throws -> String? {
        guard blockchainType == .near else {
            return nil
        }

        return try kitManager.address(account: account)
    }
}
