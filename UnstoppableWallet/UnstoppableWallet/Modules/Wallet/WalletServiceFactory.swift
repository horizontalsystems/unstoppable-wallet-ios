import HsToolKit

struct WalletServiceFactory {
    private let adapterManager: AdapterManager
    private let walletManager: WalletManager

    init(adapterManager: AdapterManager, walletManager: WalletManager) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
    }

    func walletService(account: Account) -> WalletService {
        let adapterService = WalletAdapterService(account: account, adapterManager: adapterManager)
        let service = WalletService(
            account: account,
            adapterService: adapterService,
            walletManager: walletManager
        )
        adapterService.delegate = service

        return service
    }
}
