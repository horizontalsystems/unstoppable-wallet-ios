import UserNotifications
import UIKit
import RxSwift

class NotificationManager {
    let priceAlertManager: IPriceAlertManager
    let remoteNotificationManager: IRemoteNotificationManager
    let storage: ILocalStorage

    let disposeBag = DisposeBag()

    init(priceAlertManager: IPriceAlertManager, remoteNotificationManager: IRemoteNotificationManager, storage: ILocalStorage) {
        self.priceAlertManager = priceAlertManager
        self.remoteNotificationManager = remoteNotificationManager
        self.storage = storage
    }

}

extension NotificationManager: INotificationManager {

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

            remoteNotificationManager.subscribePrice(pushToken: token, alerts: priceAlertManager.priceAlerts)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
                    .subscribe()
                    .disposed(by: disposeBag)
        }
    }

}
