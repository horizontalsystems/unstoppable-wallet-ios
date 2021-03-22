class NotificationSettingsViewItemFactory {
    private let coinManager: ICoinManager
    private let rateManager: IRateManager

    init(coinManager: ICoinManager, rateManager: IRateManager) {
        self.coinManager = coinManager
        self.rateManager = rateManager
    }

    func viewItems(alerts: [PriceAlert], notificationsOn: Bool, onTap: @escaping (PriceAlert, NotificationSettingPresentMode) -> ()) -> [NotificationSettingSectionViewItem] {
        notificationsOn ?
                alerts.compactMap { alert in
                    coinManager.coin(type: alert.coinType).map {
                        NotificationSettingSectionViewItem(title: $0.title, rowItems: [
                            NotificationSettingRowViewItem(title: "chart_alert.24h_description", value: alert.changeState.description, onTap: {
                                onTap(alert, .price)
                            }),
                            NotificationSettingRowViewItem(title: "chart_alert.trend_description", value: alert.trendState.description, onTap: {
                                onTap(alert, .trend)
                            })
                        ])
                    }
                } : []
    }

    func showResetAll(notificationsOn: Bool, alerts: [PriceAlert]) -> Bool {
        let coinCodes = rateManager.cryptoCompareCoinCodes(coinTypes: alerts.map { $0.coinType })
        return alerts.contains {
            if let coinCode = coinCodes[$0.coinType] {
                return !$0.activeTopics(coinCode: coinCode).isEmpty
            }
            return false
        } && notificationsOn
    }

}
