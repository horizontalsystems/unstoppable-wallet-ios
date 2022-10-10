import Foundation
import RxSwift
import BinanceChainKit

class BinanceKitManager {
    private let appConfigProvider: AppConfigProvider

    private weak var _binanceKit: BinanceChainKit?
    private var currentAccount: Account?

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.ethereum-kit-manager", qos: .userInitiated)

    init(appConfigProvider: AppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    private func _binanceKit(account: Account) throws -> BinanceChainKit {
        if let _binanceKit = _binanceKit, let currentAccount = currentAccount, currentAccount == account {
            return _binanceKit
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

        _binanceKit = binanceKit
        currentAccount = account

        return binanceKit
    }
}

extension BinanceKitManager {

    var binanceKit: BinanceChainKit? {
        queue.sync { _binanceKit }
    }

    func binanceKit(account: Account) throws -> BinanceChainKit {
        try queue.sync { try _binanceKit(account: account)  }
    }

}
