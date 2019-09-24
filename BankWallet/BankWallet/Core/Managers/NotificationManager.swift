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

    func showNotification(title: String, subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
//        content.subtitle = subtitle
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "my_identifier", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

}
