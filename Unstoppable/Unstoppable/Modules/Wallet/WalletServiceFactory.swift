import HsToolKit

struct WalletServiceFactory {
    private let adapterManager = Core.shared.adapterManager
    private let walletManager = Core.shared.walletManager

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
