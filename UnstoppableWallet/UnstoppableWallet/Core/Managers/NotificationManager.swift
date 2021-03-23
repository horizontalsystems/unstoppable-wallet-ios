import UserNotifications
import UIKit
import RxSwift

class NotificationManager {
    let priceAlertManager: IPriceAlertManager
    let remoteAlertManager: IRemoteAlertManager
    let storage: ILocalStorage
    let rateManager: IRateManager

    let disposeBag = DisposeBag()

    init(priceAlertManager: IPriceAlertManager, remoteAlertManager: IRemoteAlertManager, rateManager: IRateManager, storage: ILocalStorage) {
        self.priceAlertManager = priceAlertManager
        self.remoteAlertManager = remoteAlertManager
        self.rateManager = rateManager
        self.storage = storage
    }

}

extension NotificationManager: INotificationManager {

    var token: String? {
        storage.pushToken
    }

    func handleLaunch() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func requestPermission(onComplete: @escaping (Bool) -> ()) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (granted, error) in
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                onComplete(granted)
            }
        }
    }

    func removeNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func didReceivePushToken(tokenData: Data) {
        var token = ""
        for i in 0..<tokenData.count {
            token = token + String(format: "%02.2hhx", arguments: [tokenData[i]])
        }

        if storage.pushToken != token, storage.pushNotificationsOn {
            storage.pushToken = token

            let priceAlerts = priceAlertManager.priceAlerts
            let alertCoinData = rateManager.notificationCoinData(coinTypes: priceAlerts.map { $0.coinType })

            remoteAlertManager.schedule(requests: priceAlerts.reduce([PriceAlertRequest]()) { array, alert in
                var array = array
                if let coinCode = alertCoinData[alert.coinType]?.code {
                    array.append(contentsOf: PriceAlertRequest.requests(topics: alert.activeTopics(coinCode: coinCode), method: .subscribe))
                }
                return array
            })
        }
    }

}
