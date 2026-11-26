import MarketKit

/// Supplies the swap pieces of the plugin's blockchains.
protocol SwapCapability: BlockchainPlugin {
    /// A constant: read before `bootstrap`, from an un-bootstrapped instance.
    var swapBroadcasters: [ISwapBroadcasterType.Type] { get }

    /// Called once from `Core.init`, after `bootstrap` and before `Core.instance` is set: must not read `Core.shared`.
    func uSwapFinalQuoteBuilders(adapterManager: AdapterManager) -> [USwapFinalQuoteBuilder]

    /// The account's own address on `blockchainType`, used as a swap destination when no wallet is enabled.
    /// Called off the main thread; nil when the plugin has no rule for this type.
    func swapDestinationAddress(blockchainType: BlockchainType, account: Account) throws -> String?
}
