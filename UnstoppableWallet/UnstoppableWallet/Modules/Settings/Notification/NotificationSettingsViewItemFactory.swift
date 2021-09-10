class NotificationSettingsViewItemFactory {

    func viewItems(alerts: [PriceAlert], notificationsOn: Bool, onTap: @escaping (PriceAlert, NotificationSettingPresentMode) -> ()) -> [NotificationSettingSectionViewItem] {
        notificationsOn ?
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
        let hasActiveTopic = alerts.contains(where: { alert in !alert.activeTopics.isEmpty })

        return  hasActiveTopic && notificationsOn
    }

}
