import MarketKit

enum RestoreSettingsHandlerFactory {
    private static var providers: [RestoreSettingsHandler.Type] = []

    static func register(_ provider: RestoreSettingsHandler.Type) {
        providers.append(provider)
    }

    static func prepend(_ provider: RestoreSettingsHandler.Type) {
        providers.insert(provider, at: 0)
    }

    static func handler(blockchainType: BlockchainType, accountType: AccountType?) -> IRestoreSettingsHandler? {
        for provider in providers {
            if let handler = provider.instance(blockchainType: blockchainType, accountType: accountType) {
                return handler
            }
        }

        return nil
    }

    // test seam: registry is global mutable state
    static func reset() {
        providers = []
    }
}

extension RestoreSettingsHandlerFactory {
    static let unstoppableHandlers: [RestoreSettingsHandler.Type] = [
        BirthdayHeightRestoreSettingsHandler.self,
        NearAccountRestoreSettingsHandler.self,
    ]
}
