import RxSwift

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let remoteNotificationManager: IRemoteNotificationManager
    private let storage: IPriceAlertStorage
    private let localStorage: ILocalStorage

    init(walletManager: IWalletManager, remoteNotificationManager: IRemoteNotificationManager, storage: IPriceAlertStorage, localStorage: ILocalStorage) {
        self.walletManager = walletManager
        self.storage = storage
        self.remoteNotificationManager = remoteNotificationManager
        self.localStorage = localStorage

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

    func save(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        var toBeSaved = [PriceAlert]()
        var toBeDeleted = [PriceAlert]()

        for priceAlert in priceAlerts {
            if priceAlert.state == .off {
                toBeDeleted.append(priceAlert)
            } else {
                toBeSaved.append(priceAlert)
            }
        }

        var singles = [Single<()>]()

        if !toBeSaved.isEmpty {
            singles.append(
                    remoteNotificationManager.subscribePrice(pushToken: localStorage.pushToken, alerts: toBeSaved)
                            .do(onSuccess: { [weak self] in
                                self?.storage.save(priceAlerts: toBeSaved)
                            })
            )
        }

        if !toBeDeleted.isEmpty {
            singles.append(
                    remoteNotificationManager.unsubscribePrice(pushToken: localStorage.pushToken, alerts: toBeDeleted)
                            .do(onSuccess: { [weak self] in
                                self?.storage.delete(priceAlerts: toBeDeleted)
                            })
            )
        }

        return Single.zip(singles).asObservable()
    }

}
