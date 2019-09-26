import UserNotifications

class NotificationManager {
}

extension NotificationManager: INotificationManager {

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

    func willEnterForeground() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

}
