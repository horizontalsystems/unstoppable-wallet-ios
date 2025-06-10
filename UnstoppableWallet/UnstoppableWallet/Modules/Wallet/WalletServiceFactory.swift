import HsToolKit

struct WalletServiceFactory {
    private let adapterManager = App.shared.adapterManager
    private let walletManager = App.shared.walletManager

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
