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

}

extension PriceAlertHandler: IPriceAlertHandler {

    func handleAlerts(with latestRatesData: LatestRateData) {
        let priceAlerts = priceAlertStorage.priceAlerts
        var significantAlerts = [PriceAlertItem]()
        for priceAlert in priceAlerts {
            if priceAlert.state != .off, let latestRate = latestRatesData.values[priceAlert.coin.code] {
                if let alertRate = priceAlert.lastRate {
                    let diff = (latestRate - alertRate) / alertRate * 100
                    if abs(Int(truncating: diff as NSNumber)) >= priceAlert.state.rawValue {
                        priceAlert.lastRate = latestRate
                        priceAlertStorage.save(priceAlert: priceAlert)
                        let state = diff > 0 ? priceAlert.state.rawValue : -priceAlert.state.rawValue
                        significantAlerts.append(PriceAlertItem(coin: priceAlert.coin, signedState: state))
                    }
                } else {
                    priceAlert.lastRate = latestRate
                    priceAlertStorage.save(priceAlert: priceAlert)
                }
            }
        }
        let priceAlertNotifications = notificationFactory.notifications(forAlerts: significantAlerts)
        for notification in priceAlertNotifications {
            notificationManager.showNotification(title: notification.title, subtitle: notification.subtitle, body: notification.body)
        }
    }

}
