protocol IChartNotificationView: AnyObject {
    func set(coinName: String)
    func set(selectedState: AlertState)

    func showWarning()
    func hideWarning()
    func showError(error: Error)
}

protocol IChartNotificationViewDelegate {
    func viewDidLoad()
    func didSelect(state: AlertState)
    func didTapSettingsButton()
}

protocol IChartNotificationInteractor {
    func notification(coin: Coin) -> PriceAlert
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
