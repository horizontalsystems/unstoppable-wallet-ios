import RxSwift
import MarketKit

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: WalletManagerNew
    private let remoteAlertManager: IRemoteAlertManager
    private let storage: IPriceAlertStorage
    private let localStorage: ILocalStorage
    private let serializer: ISerializer

    private let updateSubject = PublishSubject<[PriceAlert]>()

    init(walletManager: WalletManagerNew, remoteAlertManager: IRemoteAlertManager, storage: IPriceAlertStorage, localStorage: ILocalStorage, serializer: ISerializer) {
        self.walletManager = walletManager
        self.remoteAlertManager = remoteAlertManager
        self.storage = storage
        self.localStorage = localStorage
        self.serializer = serializer
    }

}

extension PriceAlertManager: IPriceAlertManager {

    var updateObservable: Observable<[PriceAlert]> {
        updateSubject.asObservable()
    }

    var priceAlerts: [PriceAlert] {
        storage.priceAlerts
    }

    func priceAlert(coinType: CoinType, title: String) -> PriceAlert? {
        storage.priceAlert(coinType: coinType) ?? PriceAlert(coinType: coinType, coinTitle: title, changeState: .off, trendState: .off)
    }

    private func updateAlertsObservable(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        let oldAlerts = self.priceAlerts

        var requests = [PriceAlertRequest]()

        for alert in priceAlerts {
            let oldAlert = (oldAlerts.first { $0.coinType == alert.coinType })

            let activeTopics = alert.activeTopics.compactMap { serializer.serialize($0) }

            let oldTopicSet: Set<String>
            if let oldTopics = oldAlert?.activeTopics.compactMap({ serializer.serialize($0) }) {
                oldTopicSet = Set(oldTopics)
            } else {
                oldTopicSet = []
            }

            let subscribeTopics = Set(activeTopics).subtracting(oldTopicSet)
            let unsubscribeTopics = oldTopicSet.subtracting(Set(activeTopics))

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
            let topics = alert.activeTopics.compactMap { serializer.serialize($0) }
            return set.union(Set(topics))
        }

        let requests = PriceAlertRequest.requests(topics: activeTopics, method: localStorage.pushNotificationsOn ? .subscribe : .unsubscribe)

        return remoteAlertManager.handle(requests: requests)
    }

}
