import UserNotifications
import UIKit
import RxSwift

class NotificationManager {
    private let priceAlertManager: IPriceAlertManager
    private let remoteAlertManager: IRemoteAlertManager
    private let storage: ILocalStorage
    private let rateManager: IRateManager
    private let serializer: ISerializer

    private let disposeBag = DisposeBag()

    init(priceAlertManager: IPriceAlertManager, remoteAlertManager: IRemoteAlertManager, rateManager: IRateManager, storage: ILocalStorage, serializer: ISerializer) {
        self.priceAlertManager = priceAlertManager
        self.remoteAlertManager = remoteAlertManager
        self.rateManager = rateManager
        self.storage = storage
        self.serializer = serializer
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

            remoteAlertManager.schedule(requests: priceAlertManager.priceAlerts.reduce([PriceAlertRequest]()) { array, alert in
                let topics = alert
                        .activeTopics
                        .compactMap { serializer.serialize($0) }

                return array + PriceAlertRequest.requests(topics: Set(topics), method: .subscribe)
            })
        }
    }

}
