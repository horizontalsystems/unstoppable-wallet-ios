import RxSwift
import EthereumKit
import Erc20Kit

class EthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    weak var ethereumKit: EthereumKit.Kit?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func ethereumKit(account: Account) throws -> EthereumKit.Kit {
        if let ethereumKit = self.ethereumKit {
            return ethereumKit
        }

        guard case let .mnemonic(words, _) = account.type else {
            throw AdapterError.unsupportedAccount
        }

        let ethereumKit = try EthereumKit.Kit.instance(
                words: words,
                syncMode: .api,
                networkType: appConfigProvider.testMode ? .ropsten : .mainNet,
                infuraCredentials: appConfigProvider.infuraCredentials,
                etherscanApiKey: appConfigProvider.etherscanKey,
                walletId: account.id,
                minLogLevel: .error
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit

        return ethereumKit
    }

    var statusInfo: [(String, Any)]? {
        ethereumKit?.statusInfo()
    }

}
