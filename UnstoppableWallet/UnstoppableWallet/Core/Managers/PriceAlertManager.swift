import RxSwift

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let remoteAlertManager: IRemoteAlertManager
    private let storage: IPriceAlertStorage

    private let updateSubject = PublishSubject<[PriceAlert]>()

    init(walletManager: IWalletManager, storage: IPriceAlertStorage, remoteAlertManager: IRemoteAlertManager) {
        self.walletManager = walletManager
        self.storage = storage
        self.remoteAlertManager = remoteAlertManager

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

        let alertsToDeactivate = priceAlerts.filter { !coinCodes.contains($0.coin.code) }

        storage.save(priceAlerts: alertsToDeactivate.map { PriceAlert(coin: $0.coin, changeState: .off, trendState: .off) })

        let unsubscribeRequests = alertsToDeactivate.reduce([PriceAlertRequest]()) { array, alert in
            var array = array
            if alert.changeState != .off {
                array.append(PriceAlertRequest(topic: alert.changeTopic, method: .unsubscribe))
            }
            if alert.trendState != .off {
                array.append(PriceAlertRequest(topic: alert.trendTopic, method: .unsubscribe))
            }
            return array
        }

        remoteAlertManager.schedule(requests: unsubscribeRequests)
    }

}

extension PriceAlertManager: IPriceAlertManager {

    var updateObservable: Observable<[PriceAlert]> {
        updateSubject.asObservable()
    }

    var priceAlerts: [PriceAlert] {
        let alerts = storage.priceAlerts

        return walletManager.wallets.map { wallet in
            let coin = wallet.coin

            if let alert = alerts.first(where: { $0.coin == coin }) {
                return alert
            }

            return PriceAlert(coin: coin, changeState: .off, trendState: .off)
        }
    }

    func priceAlert(coin: Coin) -> PriceAlert {
        storage.priceAlert(coin: coin) ?? PriceAlert(coin: coin, changeState: .off, trendState: .off)
    }

    func save(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        let oldAlerts = self.priceAlerts

        var requests = [PriceAlertRequest]()

        for alert in priceAlerts {
            let oldAlert = (oldAlerts.first { $0.coin == alert.coin }) ?? PriceAlert(coin: alert.coin, changeState: .off, trendState: .off)

            if alert.changeState != oldAlert.changeState {
                if alert.changeState == .off {
                    requests.append(PriceAlertRequest(topic: oldAlert.changeTopic, method: .unsubscribe))
                } else {
                    requests.append(PriceAlertRequest(topic: alert.changeTopic, method: .subscribe))
                    if oldAlert.changeState != .off {
                        requests.append(PriceAlertRequest(topic: oldAlert.changeTopic, method: .unsubscribe))
                    }
                }
            }

            if alert.trendState != oldAlert.trendState {
                if alert.trendState == .off {
                    requests.append(PriceAlertRequest(topic: oldAlert.trendTopic, method: .unsubscribe))
                } else {
                    requests.append(PriceAlertRequest(topic: alert.trendTopic, method: .subscribe))
                    if oldAlert.trendState != .off {
                        requests.append(PriceAlertRequest(topic: oldAlert.trendTopic, method: .unsubscribe))
                    }
                }
            }
        }

        return remoteAlertManager.handle(requests: requests).do(onCompleted: { [weak self] in
            self?.storage.save(priceAlerts: priceAlerts)
            self?.updateSubject.onNext(priceAlerts)
        })
    }

    func deleteAllAlerts() -> Single<()> {
        remoteAlertManager.unsubscribeAll()
        .do(onSuccess: { [weak self] in
            self?.storage.deleteAll()
        })
    }

}
