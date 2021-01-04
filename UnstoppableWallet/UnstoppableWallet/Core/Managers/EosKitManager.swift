import RxSwift
import EosKit

class EosKitManager {
    private let appConfigProvider: IAppConfigProvider
    weak var eosKit: EosKit?

    private var currentAccount: Account?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func eosKit(account: Account) throws -> EosKit {
        if let eosKit = eosKit, let currentAccount = currentAccount, currentAccount == account {
            return eosKit
        }

        guard case let .eos(eosAccount, activePrivateKey) = account.type else {
            throw AdapterError.unsupportedAccount
        }

        let eosKit = try EosKit.instance(
                account: eosAccount,
                activePrivateKey: activePrivateKey,
                networkType: appConfigProvider.testMode ? .testNet : .mainNet,
                walletId: account.id,
                minLogLevel: .error
        )

        eosKit.refresh()

        self.eosKit = eosKit
        currentAccount = account

        return eosKit
    }

    var statusInfo: [(String, Any)]? {
        eosKit?.statusInfo
    }

}
