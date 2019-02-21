import RxSwift
import HSEthereumKit

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

        let ethereumKit = try EthereumKit.ethereumKit(
                words: authData.words,
                walletId: authData.walletId,
                testMode: appConfigProvider.testMode,
                infuraKey: appConfigProvider.infuraKey,
                etherscanKey: appConfigProvider.etherscanKey
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit
        return ethereumKit
    }

    func clear() {
        ethereumKit?.clear()
    }

}
