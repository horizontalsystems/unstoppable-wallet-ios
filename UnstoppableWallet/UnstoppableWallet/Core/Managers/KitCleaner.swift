import Foundation

class KitCleaner {
    private let accountManager: IAccountManager

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager
    }

}

extension KitCleaner: IKitCleaner {

    func clear() {
        let accountIds = accountManager.accounts.map { $0.id }

        DispatchQueue.global(qos: .background).async {
            try? BitcoinAdapter.clear(except: accountIds)
            try? LitecoinAdapter.clear(except: accountIds)
            try? BitcoinCashAdapter.clear(except: accountIds)
            try? DashAdapter.clear(except: accountIds)
            try? EvmAdapter.clear(except: accountIds)
            try? Evm20Adapter.clear(except: accountIds)
            try? BinanceAdapter.clear(except: accountIds)
            try? ZcashAdapter.clear(except: accountIds)
        }
    }

}
