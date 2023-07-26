import HsToolKit

struct WalletElementServiceFactory {
    private let adapterManager: AdapterManager
    private let walletManager: WalletManager
    private let cexAssetManager: CexAssetManager

    init(adapterManager: AdapterManager, walletManager: WalletManager, cexAssetManager: CexAssetManager) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
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
        case .cex(let cexAccount):
            return WalletCexElementService(account: account, provider: cexAccount.assetProvider, cexAssetManager: cexAssetManager)
        }
    }

}
