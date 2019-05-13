import RxSwift
import EthereumKit
import Erc20Kit

protocol IEthereumKitManager {
    func ethereumKit(authData: AuthData) throws -> EthereumKit
}

class EthereumKitManager: IEthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    private weak var ethereumKit: EthereumKit?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func ethereumKit(authData: AuthData) throws -> EthereumKit {
        if let ethereumKit = self.ethereumKit {
            return ethereumKit
        }

        let ethereumKit = try EthereumKit.instance(
                words: authData.words,
                syncMode: .api,
                networkType: appConfigProvider.testMode ? .ropsten : .mainNet,
                infuraCredentials: appConfigProvider.infuraCredentials,
                etherscanApiKey: appConfigProvider.etherscanKey,
                walletId: authData.walletId,
                minLogLevel: .error
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit

        return ethereumKit
    }

}
