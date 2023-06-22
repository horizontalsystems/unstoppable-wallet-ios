import HsToolKit

struct WalletElementServiceFactory {
    private let adapterManager: AdapterManager
    private let walletManager: WalletManager
    private let cexAssetManager: CexAssetManager
    private let cexProviderFactory: CexProviderFactory

    init(adapterManager: AdapterManager, walletManager: WalletManager, cexAssetManager: CexAssetManager, cexProviderFactory: CexProviderFactory) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
        self.cexAssetManager = cexAssetManager
        self.cexProviderFactory = cexProviderFactory
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
            let provider = cexProviderFactory.provider(type: type)
            return WalletCexElementService(account: account, provider: provider, cexAssetManager: cexAssetManager)
        }
    }

}
