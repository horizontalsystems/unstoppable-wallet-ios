import UserNotifications
import UIKit

class NotificationManager {
}

extension NotificationManager: INotificationManager {

    var allowedBackgroundFetching: Bool {
        UIApplication.shared.backgroundRefreshStatus == .available
    }

    func requestPermission(onComplete: @escaping (Bool) -> ()) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (granted, error) in
            DispatchQueue.main.async {
                onComplete(granted)
            }
        }
    }

    func show(notification: AlertNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "my_identifier_\(notification.title)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func removeNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

}
