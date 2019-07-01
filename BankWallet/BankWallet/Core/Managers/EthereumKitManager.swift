import RxSwift
import EthereumKit
import Erc20Kit

protocol IEthereumKitManager {
    var ethereumKit: EthereumKit? { get }
    func ethereumKit(wallet: Wallet) throws -> EthereumKit
}

class EthereumKitManager: IEthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    weak var ethereumKit: EthereumKit?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func ethereumKit(wallet: Wallet) throws -> EthereumKit {
        if let ethereumKit = self.ethereumKit {
            return ethereumKit
        }

        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        let ethereumKit = try EthereumKit.instance(
                words: words,
                syncMode: .api,
                networkType: appConfigProvider.testMode ? .ropsten : .mainNet,
                infuraCredentials: appConfigProvider.infuraCredentials,
                etherscanApiKey: appConfigProvider.etherscanKey,
                walletId: wallet.account.id,
                minLogLevel: .error
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit

        return ethereumKit
    }

}
