import MarketKit
import HsToolKit

struct WalletElementServiceFactory {
    private let adapterManager: AdapterManager
    private let walletManager: WalletManager
    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit

    init(adapterManager: AdapterManager, walletManager: WalletManager, networkManager: NetworkManager, marketKit: MarketKit.Kit) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
        self.networkManager = networkManager
        self.marketKit = marketKit
    }

    func elementService(accountType: AccountType) -> IWalletElementService {
        switch accountType {
        case .mnemonic, .evmPrivateKey, .evmAddress, .tronAddress, .hdExtendedKey:
            let adapterService = WalletAdapterService(adapterManager: adapterManager)
            let elementService = WalletBlockchainElementService(
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
                        marketKit: marketKit,
                        apiKey: apiKey,
                        secret: secret
                )
            case .coinzix(let authToken, let secret):
                provider = CoinzixCexProvider(
                        networkManager: networkManager,
                        marketKit: marketKit,
                        authToken: authToken,
                        secret: secret
                )
            }

            return WalletCexElementService(provider: provider)
        }
    }

}
