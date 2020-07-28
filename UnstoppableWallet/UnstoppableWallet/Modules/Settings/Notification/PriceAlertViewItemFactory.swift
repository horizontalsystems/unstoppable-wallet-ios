class PriceAlertViewItemFactory {

    func viewItems(alerts: [PriceAlert]) -> [PriceAlertViewItem] {
        alerts.map { alert in
            PriceAlertViewItem(title: alert.coin.title, code: alert.coin.code, changeState: alert.changeState, trendState: alert.trendState)
        }
    }

}
