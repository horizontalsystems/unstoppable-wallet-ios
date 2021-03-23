class NotificationSettingsViewItemFactory {
    private let rateManager: IRateManager

    init(rateManager: IRateManager) {
        self.rateManager = rateManager
    }

    func viewItems(alerts: [PriceAlert], notificationsOn: Bool, onTap: @escaping (PriceAlert, NotificationSettingPresentMode) -> ()) -> [NotificationSettingSectionViewItem] {
        return notificationsOn ?
                alerts.map { alert in
                    NotificationSettingSectionViewItem(title: alert.coinTitle, rowItems: [
                        NotificationSettingRowViewItem(title: "chart_alert.24h_description", value: alert.changeState.description, onTap: {
                            onTap(alert, .price)
                        }),
                        NotificationSettingRowViewItem(title: "chart_alert.trend_description", value: alert.trendState.description, onTap: {
                            onTap(alert, .trend)
                        })
                    ])
                } : []
    }

    func showResetAll(notificationsOn: Bool, alerts: [PriceAlert]) -> Bool {
        let coinData = rateManager.notificationCoinData(coinTypes: alerts.map { $0.coinType })
        return alerts.contains {
            if let coinCode = coinData[$0.coinType]?.code {
                return !$0.activeTopics(coinCode: coinCode).isEmpty
            }
            return false
        } && notificationsOn
    }

}
