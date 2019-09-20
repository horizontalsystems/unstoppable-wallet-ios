import RxSwift

class PriceAlertManager {
    private let walletManager: IWalletManager
    private let storage: IPriceAlertStorage

    init(walletManager: IWalletManager, storage: IPriceAlertStorage) {
        self.walletManager = walletManager
        self.storage = storage
    }

}

extension PriceAlertManager: IPriceAlertManager {

    var priceAlerts: [PriceAlert] {
        let alerts = storage.priceAlerts

        return walletManager.wallets.map { wallet in
            let coin = wallet.coin

            if let alert = alerts.first(where: { $0.coin == coin }) {
                return alert
            }

            return PriceAlert(coin: coin, state: .off)
        }
    }

    func save(priceAlert: PriceAlert) {
        if priceAlert.state == .off {
            storage.delete(priceAlert: priceAlert)
        } else {
            storage.save(priceAlert: priceAlert)
        }
    }

}
