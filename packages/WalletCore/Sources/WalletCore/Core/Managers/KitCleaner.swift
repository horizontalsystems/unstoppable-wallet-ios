import Foundation

public class KitCleaner {
    private let accountManager: AccountManager
    private let registry: BlockchainRegistry

    public init(accountManager: AccountManager, registry: BlockchainRegistry) {
        self.accountManager = accountManager
        self.registry = registry
    }
}

public extension KitCleaner {
    func clear() {
        let accountIds = accountManager.allAccounts.map(\.id)
        let lifecycleCapabilities = registry.lifecycleCapabilities

        DispatchQueue.global(qos: .background).async {
            try? BitcoinAdapter.clear(except: accountIds)
            try? LitecoinAdapter.clear(except: accountIds)
            try? BitcoinCashAdapter.clear(except: accountIds)
            try? DashAdapter.clear(except: accountIds)
            try? EvmAdapter.clear(except: accountIds)
            try? ZcashAdapter.clear(except: accountIds)
            try? TronAdapter.clear(except: accountIds)
            try? MoneroAdapter.clear(except: accountIds)
            try? ZanoAdapter.clear(except: accountIds)
            try? XrpAdapter.clear(except: accountIds)
            for capability in lifecycleCapabilities {
                try? capability.clear(exceptAccountIds: accountIds)
            }
        }
    }
}
