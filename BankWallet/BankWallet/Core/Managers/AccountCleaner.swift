import Foundation

class AccountCleaner: IAccountCleaner {

    func clearAll(except existingAccounts: [Account]) {
        let accountIds = existingAccounts.map { $0.id }

        DispatchQueue.global(qos: .background).async {
            try? BitcoinAdapter.clear(except: accountIds)
            try? BitcoinCashAdapter.clear(except: accountIds)
            try? DashAdapter.clear(except: accountIds)
            try? EthereumAdapter.clear(except: accountIds)
            try? Erc20Adapter.clear(except: accountIds)
            try? EosAdapter.clear(except: accountIds)
            try? BinanceAdapter.clear(except: accountIds)
        }
    }

}
