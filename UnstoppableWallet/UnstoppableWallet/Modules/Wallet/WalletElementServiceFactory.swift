import HsToolKit

struct WalletElementServiceFactory {
    private let adapterManager: AdapterManager
    private let walletManager: WalletManager
    private let networkManager: NetworkManager
    private let cexAssetManager: CexAssetManager

    init(adapterManager: AdapterManager, walletManager: WalletManager, networkManager: NetworkManager, cexAssetManager: CexAssetManager) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
        self.networkManager = networkManager
        self.cexAssetManager = cexAssetManager
    }

    func elementService(account: Account) -> IWalletElementService {
        switch account.type {
        case .mnemonic, .evmPrivateKey, .evmAddress, .tronAddress, .hdExtendedKey:
            let adapterService = WalletAdapterService(account: account, adapterManager: adapterManager)
            let elementService = WalletBlockchainElementService(
                    account: account,
                    adapterService: adapterService,
                    walletManager: walletManager
            )
            adapterService.delegate = elementService

            return elementService
        case .cex(let type):
            let provider: ICexProvider

            switch type {
            case .binance(let apiKey, let secret):
                provider = BinanceCexProvider(
                        networkManager: networkManager,
                        apiKey: apiKey,
                        secret: secret
                )
            case .coinzix(let authToken, let secret):
                provider = CoinzixCexProvider(
                        networkManager: networkManager,
                        authToken: authToken,
                        secret: secret
                )
            }

            return WalletCexElementService(account: account, provider: provider, cexAssetManager: cexAssetManager)
        }
    }

}
