import RxSwift
import BinanceChainKit

class BinanceKitManager {
    private let appConfigProvider: IAppConfigProvider
    weak var binanceKit: BinanceChainKit?

    private var currentAccount: Account?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func binanceKit(account: Account) throws -> BinanceChainKit {
        if let binanceKit = binanceKit, let currentAccount = currentAccount, currentAccount == account {
            return binanceKit
        }

        guard let seed = account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let binanceKit = try BinanceChainKit.instance(
                seed: seed,
                networkType: appConfigProvider.testMode ? .testNet : .mainNet,
                walletId: account.id,
                minLogLevel: .error
        )

        binanceKit.refresh()

        self.binanceKit = binanceKit
        currentAccount = account

        return binanceKit
    }

    func refresh() {
        binanceKit?.refresh()
    }

    var statusInfo: [(String, Any)]? {
        binanceKit?.statusInfo
    }

}
