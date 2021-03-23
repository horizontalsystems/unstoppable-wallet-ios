import RxSwift
import CoinKit

class PriceAlertManager {
    private let disposeBag = DisposeBag()

    private let walletManager: IWalletManager
    private let remoteAlertManager: IRemoteAlertManager
    private let rateManager: IRateManager
    private let storage: IPriceAlertStorage
    private let localStorage: ILocalStorage

    private let updateSubject = PublishSubject<[PriceAlert]>()

    init(walletManager: IWalletManager, remoteAlertManager: IRemoteAlertManager, rateManager: IRateManager, storage: IPriceAlertStorage, localStorage: ILocalStorage) {
        self.walletManager = walletManager
        self.remoteAlertManager = remoteAlertManager
        self.rateManager = rateManager
        self.storage = storage
        self.localStorage = localStorage
    }

    func alertNotificationAllowed(coinType: CoinType) -> Bool {
        rateManager.notificationDataExist(coinType: coinType)
    }

}

extension PriceAlertManager: IPriceAlertManager {

    var updateObservable: Observable<[PriceAlert]> {
        updateSubject.asObservable()
    }

    var priceAlerts: [PriceAlert] {
        var alerts = storage.priceAlerts.filter { rateManager.notificationDataExist(coinType: $0.coinType) }

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
        guard alertNotificationAllowed(coinType: coinType) == true else {
            return nil
        }

        return storage.priceAlert(coinType: coinType) ?? PriceAlert(coinType: coinType, coinTitle: title, changeState: .off, trendState: .off)
    }

    private func updateAlertsObservable(priceAlerts: [PriceAlert]) -> Observable<[()]> {
        let oldAlerts = self.priceAlerts
        let alertCoinData = rateManager.notificationCoinData(coinTypes: priceAlerts.map { $0.coinType })

        var requests = [PriceAlertRequest]()

        for alert in priceAlerts {
            let oldAlert = (oldAlerts.first { $0.coinType == alert.coinType })

            if let coinCode = alertCoinData[alert.coinType]?.code {
                let oldTopics = oldAlert?.activeTopics(coinCode: coinCode)
                let activeTopics = alert.activeTopics(coinCode: coinCode)

                let subscribeTopics = alert.activeTopics(coinCode: coinCode).subtracting(oldTopics ?? [])
                let unsubscribeTopics = oldTopics?.subtracting(activeTopics) ?? []

                requests.append(contentsOf: PriceAlertRequest.requests(topics: subscribeTopics, method: .subscribe))
                requests.append(contentsOf: PriceAlertRequest.requests(topics: unsubscribeTopics, method: .unsubscribe))
            }
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
        let alertCoinData = rateManager.notificationCoinData(coinTypes: priceAlerts.map { $0.coinType })

        let activeTopics = priceAlerts.reduce(Set<String>()) { set, alert in
            var set = set
            if let coinCode = alertCoinData[alert.coinType]?.code {
                set.formUnion(alert.activeTopics(coinCode: coinCode))
            }
            return set
        }

        let requests = PriceAlertRequest.requests(topics: activeTopics, method: localStorage.pushNotificationsOn ? .subscribe : .unsubscribe)

        return remoteAlertManager.handle(requests: requests)
    }

}
