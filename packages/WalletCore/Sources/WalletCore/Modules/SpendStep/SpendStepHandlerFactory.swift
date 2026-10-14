enum SpendStepHandlerFactory {
    private static var providers: [SpendStepHandler.Type] = []

    static func register(_ provider: SpendStepHandler.Type) {
        providers.append(provider)
    }

    static func prepend(_ provider: SpendStepHandler.Type) {
        providers.insert(provider, at: 0)
    }

    static func handler(wallet: Wallet, purpose: SpendStepPurpose) -> ISpendStepHandler? {
        if wallet.account.watchAccount {
            return nil
        }

        for provider in providers {
            if let handler = provider.instance(wallet: wallet, purpose: purpose) {
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

extension SpendStepHandlerFactory {
    static let unstoppableHandlers: [SpendStepHandler.Type] = [
        ZcashShieldStepHandler.self,
    ]
}
