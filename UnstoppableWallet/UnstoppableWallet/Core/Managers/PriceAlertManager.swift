import RxSwift

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let remoteAlertManager: IRemoteAlertManager
    private let storage: IPriceAlertStorage
    private let localStorage: ILocalStorage

    private let updateSubject = PublishSubject<[PriceAlert]>()

    init(walletManager: IWalletManager, remoteAlertManager: IRemoteAlertManager, storage: IPriceAlertStorage, localStorage: ILocalStorage) {
        self.walletManager = walletManager
        self.storage = storage
        self.remoteAlertManager = remoteAlertManager
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
        let coinIds = wallets.map { $0.coin.id }

        let alertsToDeactivate = storage.activePriceAlerts.filter { !coinIds.contains($0.coin.id) }

        storage.save(priceAlerts: alertsToDeactivate.map { PriceAlert(coin: $0.coin, changeState: .off, trendState: .off) })

        let unsubscribeRequests = alertsToDeactivate.reduce([PriceAlertRequest]()) { array, alert in
            var array = array
            array.append(contentsOf: PriceAlertRequest.requests(topics: alert.activeTopics, method: .unsubscribe))
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

    private func updateAlertsObservable(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        let oldAlerts = self.priceAlerts

        var requests = [PriceAlertRequest]()

        for alert in priceAlerts {
            let oldAlert = (oldAlerts.first { $0.coin == alert.coin })

            let subscribeTopics = alert.activeTopics.subtracting(oldAlert?.activeTopics ?? [])
            let unsubscribeTopics = oldAlert?.activeTopics.subtracting(alert.activeTopics) ?? []

            requests.append(contentsOf: PriceAlertRequest.requests(topics: subscribeTopics, method: .subscribe))
            requests.append(contentsOf: PriceAlertRequest.requests(topics: unsubscribeTopics, method: .unsubscribe))
        }

        return remoteAlertManager.handle(requests: requests)
    }

    func save(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        updateAlertsObservable(priceAlerts: priceAlerts)
                .do(onCompleted: { [weak self] in
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

    func updateTopics() -> Observable<[()]> {
        let activeTopics = priceAlerts.reduce(Set<String>()) { set, alert in
            var set = set
            set.formUnion(alert.activeTopics)
            return set
        }

        let requests = PriceAlertRequest.requests(topics: activeTopics, method: localStorage.pushNotificationsOn ? .subscribe : .unsubscribe)

        return remoteAlertManager.handle(requests: requests)
    }

}
