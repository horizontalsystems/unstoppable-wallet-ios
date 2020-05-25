import Foundation

class PriceAlertHandler {
    private let priceAlertStorage: IPriceAlertStorage
    private let notificationManager: INotificationManager
    private let notificationFactory: INotificationFactory

    init(priceAlertStorage: IPriceAlertStorage, notificationManager: INotificationManager, notificationFactory: INotificationFactory) {
        self.priceAlertStorage = priceAlertStorage
        self.notificationManager = notificationManager
        self.notificationFactory = notificationFactory
    }

    func signedState(alertRate: Decimal, latestRate: Decimal, threshold: Int) -> Int? {
        let diff = (latestRate - alertRate) / alertRate * 100

        guard abs(Int(truncating: diff as NSNumber)) >= threshold else {
            return nil
        }

        return diff.isSignMinus ? -threshold : threshold
    }

}

extension PriceAlertHandler: IPriceAlertHandler {

//    func handleAlerts(with latestRatesData: LatestRateData) {
//        let priceAlerts = priceAlertStorage.activePriceAlerts
//        var significantAlerts = [PriceAlertItem]()
//        var changedAlerts = [PriceAlert]()
//
//        for priceAlert in priceAlerts {
//            guard let latestRate = latestRatesData.values[priceAlert.coin.code] else {
//                continue
//            }
//
//            guard let alertRate = priceAlert.lastRate else {
//                priceAlert.lastRate = latestRate
//                changedAlerts.append(priceAlert)
//                continue
//            }
//
//            guard let signedState = signedState(alertRate: alertRate, latestRate: latestRate, threshold: priceAlert.state.rawValue) else {
//                continue
//            }
//
//            priceAlert.lastRate = latestRate
//            changedAlerts.append(priceAlert)
//            significantAlerts.append(PriceAlertItem(coin: priceAlert.coin, signedState: signedState))
//        }
//
//        if !changedAlerts.isEmpty {
//            priceAlertStorage.save(priceAlerts: changedAlerts)
//        }
//        // we must save only alerts which we show in notification
//        let notifications = notificationFactory.notifications(forAlerts: significantAlerts)
//        for notification in notifications {
//            notificationManager.show(notification: notification)
//        }
//    }

}
