class NotificationSettingsInteractor {
    private let walletManager: IWalletManager

    init(walletManager: IWalletManager) {
        self.walletManager = walletManager
    }

}

extension NotificationSettingsInteractor: INotificationSettingsInteractor {

    var alerts: [PriceAlert] {
        return walletManager.wallets.map {
            PriceAlert(coin: $0.coin, state: .off)
        }
    }

}
