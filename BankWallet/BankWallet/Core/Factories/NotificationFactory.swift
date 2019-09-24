struct PriceAlertItem {
    let coin: Coin
    let signedState: Int
}

class NotificationFactory {
    private static let separatedAlertCount = 2
    private let emojiHelper: IEmojiHelper

    init(emojiHelper: IEmojiHelper) {
        self.emojiHelper = emojiHelper
    }

    private func singleNotification(item: PriceAlertItem) -> AlertNotification {
        let title = item.coin.title + " " + emojiHelper.title(forState: item.signedState)

        let directionString = (item.signedState > 0 ? "price_notification.up" : "price_notification.down").localized.capitalized
        let body = directionString + " \(abs(item.signedState))% " + emojiHelper.body(forState: item.signedState)

        return AlertNotification(title: title, body: body)
    }

    private func multipleNotification(items: [PriceAlertItem]) -> AlertNotification {
        let title = "price_notification.multi_title".localized + " " + emojiHelper.multiAlerts

        let sortedItems = items.sorted { item, item2 in item.signedState > item2.signedState }
        let body = sortedItems.map { bodyPart(item: $0) }.joined(separator: ", ")

        return AlertNotification(title: title, body: body)
    }

    private func bodyPart(item: PriceAlertItem) -> String {
        let directionString = (item.signedState > 0 ? "price_notification.up" : "price_notification.down").localized
        return item.coin.code + " " + directionString + " \(abs(item.signedState))%"
    }

}

extension NotificationFactory: INotificationFactory {

    func notifications(forAlerts alertItems: [PriceAlertItem]) -> [AlertNotification] {
        if alertItems.count <= NotificationFactory.separatedAlertCount {
            return alertItems.map { singleNotification(item: $0) }
        } else {
            return [multipleNotification(items: alertItems)]
        }
    }

}
