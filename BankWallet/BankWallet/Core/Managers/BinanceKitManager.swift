import RxSwift
import BinanceChainKit

class BinanceKitManager {
    private let appConfigProvider: IAppConfigProvider
    weak var binanceKit: BinanceChainKit?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func binanceKit(account: Account) throws -> BinanceChainKit {
        if let binanceKit = self.binanceKit {
            return binanceKit
        }

        guard case let .mnemonic(words, _) = account.type else {
            throw AdapterError.unsupportedAccount
        }

        let binanceKit = try BinanceChainKit.instance(
                words: words,
                networkType: appConfigProvider.testMode ? .testNet : .mainNet,
                walletId: account.id,
                minLogLevel: .error
        )

        binanceKit.refresh()

        self.binanceKit = binanceKit

        return binanceKit
    }

    func refresh() {
        binanceKit?.refresh()
    }

    var statusInfo: [(String, Any)]? {
        binanceKit?.statusInfo
    }

}
