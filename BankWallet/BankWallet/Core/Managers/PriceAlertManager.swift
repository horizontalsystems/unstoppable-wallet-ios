import RxSwift

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let storage: IPriceAlertStorage

    init(walletManager: IWalletManager, storage: IPriceAlertStorage) {
        self.walletManager = walletManager
        self.storage = storage

        walletManager.walletsUpdatedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] wallets in
                    self?.onUpdate(wallets: wallets)
                })
                .disposed(by: disposeBag)
    }

    private func onUpdate(wallets: [Wallet]) {
        let coinCodes = wallets.map { $0.coin.code }

        storage.deleteExcluding(coinCodes: coinCodes)
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

    func save(priceAlerts: [PriceAlert]) {
        var toBeSaved = [PriceAlert]()
        var toBeDeleted = [PriceAlert]()

        for priceAlert in priceAlerts {
            if priceAlert.state == .off {
                toBeDeleted.append(priceAlert)
            } else {
                toBeSaved.append(priceAlert)
            }
        }

        if !toBeSaved.isEmpty {
            storage.save(priceAlerts: toBeSaved)
        }

        if !toBeDeleted.isEmpty {
            storage.delete(priceAlerts: toBeDeleted)
        }
    }

}
