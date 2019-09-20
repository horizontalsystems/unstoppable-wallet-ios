class PriceAlertViewItemFactory {

    func viewItems(alerts: [PriceAlert]) -> [PriceAlertViewItem] {
        return alerts.map { alert in
            return PriceAlertViewItem(title: alert.coin.title, code: alert.coin.code, state: alert.state)
        }
    }

}
