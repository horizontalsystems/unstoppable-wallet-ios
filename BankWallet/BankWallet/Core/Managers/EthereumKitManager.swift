import HSEthereumKit

class EthereumKitManager: IEthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    private weak var ethereumKit: EthereumKit?

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func ethereumKit(authData: AuthData) -> EthereumKit {
        if let ethereumKit = self.ethereumKit {
            return ethereumKit
        }
        let network: EthereumKit.NetworkType = appConfigProvider.testMode ? .testNet : .mainNet

        let ethereumKit = EthereumKit(withWords: authData.words, networkType: network, walletId: authData.walletId, infuraKey: appConfigProvider.infuraKey, etherscanKey: appConfigProvider.etherscanKey)
        ethereumKit.start()
        self.ethereumKit = ethereumKit
        return ethereumKit
    }

    func clear() throws {
        try ethereumKit?.clear()
    }

}
