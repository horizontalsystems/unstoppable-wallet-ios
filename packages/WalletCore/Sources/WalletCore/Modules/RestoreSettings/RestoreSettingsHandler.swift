import MarketKit

/// Asks the user the restore settings a chain needs, such as a birthday height or the NEAR account a
/// phrase opens. An instance is made per request and calls exactly one of its callbacks.
protocol IRestoreSettingsHandler {
    func request(token: Token, statPage: StatPage?, onEnter: @escaping (RestoreSettings) -> Void, onCancel: @escaping () -> Void)
}

class RestoreSettingsHandler {
    init() {}

    // nil when the chain or the account has nothing to ask
    class func instance(blockchainType _: BlockchainType, accountType _: AccountType?) -> IRestoreSettingsHandler? { nil }
}
