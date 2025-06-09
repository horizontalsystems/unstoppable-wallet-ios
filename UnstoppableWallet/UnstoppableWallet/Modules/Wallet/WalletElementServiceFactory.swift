import HsToolKit

struct WalletElementServiceFactory {
    private let adapterManager: AdapterManager
    private let walletManager: WalletManager

    init(adapterManager: AdapterManager, walletManager: WalletManager) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
    }

    func elementService(account: Account) -> IWalletElementService {
        let adapterService = WalletAdapterService(account: account, adapterManager: adapterManager)
        let elementService = WalletBlockchainElementService(
            account: account,
            adapterService: adapterService,
            walletManager: walletManager
        )
        adapterService.delegate = elementService

        return elementService
    }
}
