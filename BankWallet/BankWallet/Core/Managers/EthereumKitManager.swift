import RxSwift
import EthereumKit
import Erc20Kit

protocol IEthereumKitManager {
    func ethereumKit(authData: AuthData) throws -> EthereumKit
    func clear()
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
                syncMode: .api(infuraProjectId: appConfigProvider.infuraKey),
                networkType: appConfigProvider.testMode ? .ropsten : .mainNet,
                etherscanApiKey: appConfigProvider.etherscanKey,
                walletId: authData.walletId,
                minLogLevel: .error
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit
        return ethereumKit
    }

    func clear() {
        ethereumKit?.clear()
    }

}
