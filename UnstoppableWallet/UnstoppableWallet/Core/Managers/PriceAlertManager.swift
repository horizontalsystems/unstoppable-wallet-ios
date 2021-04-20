import RxSwift
import CoinKit

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let remoteAlertManager: IRemoteAlertManager
    private let rateManager: IRateManager
    private let storage: IPriceAlertStorage
    private let localStorage: ILocalStorage
    private let serializer: ISerializer

    private let updateSubject = PublishSubject<[PriceAlert]>()

    init(walletManager: IWalletManager, remoteAlertManager: IRemoteAlertManager, rateManager: IRateManager, storage: IPriceAlertStorage, localStorage: ILocalStorage, serializer: ISerializer) {
        self.walletManager = walletManager
        self.remoteAlertManager = remoteAlertManager
        self.rateManager = rateManager
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
        var alerts = storage.priceAlerts

        let walletAlerts = walletManager.wallets.compactMap { wallet -> PriceAlert? in
            let coin = wallet.coin

            if let alertIndex = alerts.firstIndex(where: { $0.coinType == coin.type }) {
                let walletAlert = alerts[alertIndex]
                alerts.remove(at: alertIndex)

                return walletAlert
            }

            return PriceAlert(coinType: coin.type, coinTitle: coin.title, changeState: .off, trendState: .off)
        }

        let savedOtherAlerts = alerts.compactMap { alert -> PriceAlert? in
            if alert.trendState == .off, alert.changeState == .off {
                return nil
            }

            return alert
        }

        return walletAlerts + savedOtherAlerts
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
