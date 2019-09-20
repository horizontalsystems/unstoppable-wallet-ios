import UIKit
import UserNotifications

class NotificationManager {
}

extension NotificationManager: INotificationManager {

    var isEnabled: Bool {
//        UNUserNotificationCenter.current().getNotificationSettings { settings in
//            settings.authorizationStatus
//        }

//        guard let settings = UIApplication.shared.currentUserNotificationSettings else {
//            return false
//        }
//        return !settings.types.isEmpty
        return true
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (granted, error) in
            if granted {
                print("yes")
            } else {
                print("No")
            }
        }
    }

    func showNotification(title: String, subtitle: String, body: String) {
        print("title: \(title), subtitle: \(subtitle), body: \(body), thread: \(Thread.current)")

        let content = UNMutableNotificationContent()
        content.title = title
//        content.subtitle = subtitle
        content.body = body

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "my_identifier", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

}
