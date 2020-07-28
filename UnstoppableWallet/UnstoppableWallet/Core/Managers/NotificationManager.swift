import UserNotifications
import UIKit
import RxSwift

class NotificationManager {
    let priceAlertManager: IPriceAlertManager
    let remoteAlertManager: IRemoteAlertManager
    let storage: ILocalStorage

    let disposeBag = DisposeBag()

    init(priceAlertManager: IPriceAlertManager, remoteAlertManager: IRemoteAlertManager, storage: ILocalStorage) {
        self.priceAlertManager = priceAlertManager
        self.remoteAlertManager = remoteAlertManager
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
            UIApplication.shared.registerForRemoteNotifications()

            DispatchQueue.main.async {
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

        if storage.pushToken != token {
            storage.pushToken = token

            remoteAlertManager.schedule(requests: priceAlertManager.priceAlerts.reduce([PriceAlertRequest]()) {
                var array = $0
                if $1.changeState != .off {
                    array.append(PriceAlertRequest(topic: $1.changeTopic, method: .subscribe))
                }
                if $1.trendState != .off {
                    array.append(PriceAlertRequest(topic: $1.trendTopic, method: .subscribe))
                }
                return array
            })
        }
    }

}
