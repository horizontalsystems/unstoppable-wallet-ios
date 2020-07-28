protocol IChartNotificationView: AnyObject {
    func set(coinName: String)
    func set(alert: PriceAlert)

    func showWarning()
    func hideWarning()
    func showError(error: Error)
}

protocol IChartNotificationViewDelegate {
    func viewDidLoad()
    func didSelect(changeState: PriceAlert.ChangeState)
    func didSelect(trendState: PriceAlert.TrendState)
    func didTapSettingsButton()
}

protocol IChartNotificationInteractor {
    func priceAlert(coin: Coin) -> PriceAlert
    func requestPermission()
    func save(priceAlert: PriceAlert)
}

protocol IChartNotificationInteractorDelegate: AnyObject {
    func didGrantPermission()
    func didDenyPermission()
    func didEnterForeground()
    func didFailSaveAlerts(error: Error)
}

protocol IChartNotificationRouter {
    func openSettings()
}
