import MarketKit

/// A blockchain whose addresses the watch screen recognises.
struct WatchAddressSupport {
    let blockchainType: BlockchainType
    /// Position among the watch screen's address parsers; lower is tried first.
    let priority: Int
}

/// Supplies the account rules of the plugin's blockchains: token support and watch accounts.
protocol AccountCapability: BlockchainPlugin {
    /// nil when the token is not on one of the plugin's blockchains. Pure; called on any thread.
    func supports(accountType: AccountType, token: Token) -> Bool?
    /// A constant.
    var watchAddressSupports: [WatchAddressSupport] { get }
    /// The watch account a parsed address opens; nil when the address is not the plugin's.
    func watchAccountType(address: Address) throws -> AccountType?
}
