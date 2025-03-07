import Foundation

class KitCleaner {
    private let accountManager: AccountManager

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
    }
}

extension KitCleaner {
    func clear() {
        let accountIds = accountManager.accounts.map(\.id)

        DispatchQueue.global(qos: .background).async {
            try? BitcoinAdapter.clear(except: accountIds)
            try? LitecoinAdapter.clear(except: accountIds)
            try? BitcoinCashAdapter.clear(except: accountIds)
            try? DashAdapter.clear(except: accountIds)
            try? EvmAdapter.clear(except: accountIds)
            try? EvmNftAdapter.clear(except: accountIds)
            try? ZcashAdapter.clear(except: accountIds)
            try? TronAdapter.clear(except: accountIds)
        }
    }
}
