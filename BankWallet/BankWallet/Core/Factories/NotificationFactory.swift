struct PriceAlertItem {
    let coin: Coin
    let signedState: Int
}

class NotificationFactory: INotificationFactory {
    private static let separatedAlertCount = 2
    private let emojiHelper: IEmojiHelper

    init(emojiHelper: IEmojiHelper) {
        self.emojiHelper = emojiHelper
    }

    func notifications(forAlerts alertItems: [PriceAlertItem]) -> [AlertNotification] {
        if alertItems.count <= NotificationFactory.separatedAlertCount {
            var alertNotifications = [AlertNotification]()
            for item in alertItems {
                let title = item.coin.title + " " + emojiHelper.title(forState: item.signedState)
                let directionString = (item.signedState > 0 ? "price_notification.up" : "price_notification.down").localized.capitalized
                let body = directionString + " \(abs(item.signedState))% " + emojiHelper.body(forState: item.signedState)

                alertNotifications.append(AlertNotification(title: title, subtitle: "", body: body))
            }
            return alertNotifications
        } else {
            var bodyParts = [String]()
            let sortedItems = alertItems.sorted { item, item2 in item.signedState > item2.signedState }
            for item in sortedItems {
                let directionString = (item.signedState > 0 ? "price_notification.up" : "price_notification.down").localized
                let body = item.coin.code + " " + directionString + " \(abs(item.signedState))%"
                bodyParts.append(body)
            }
            let title = "price_notification.multi_title".localized + " " + emojiHelper.multiAlerts
            let body = bodyParts.joined(separator: ", ")
            return [AlertNotification(title: title, subtitle: "", body: body)]
        }
    }

}
