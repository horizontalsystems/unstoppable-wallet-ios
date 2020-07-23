class ChartNotificationPresenter {
    weak var view: IChartNotificationView?

    private let router: IChartNotificationRouter
    private let interactor: IChartNotificationInteractor

    private var notification: PriceAlert

    private let coin: Coin

    init(router: IChartNotificationRouter, interactor: IChartNotificationInteractor, coin: Coin) {
        self.router = router
        self.interactor = interactor

        self.coin = coin

        self.notification = interactor.notification(coin: coin)
    }

    private func handleUpdated(alert: PriceAlert) {
        interactor.save(priceAlert: alert)

        view?.set(selectedState: alert.state)
    }

}

extension ChartNotificationPresenter: IChartNotificationViewDelegate {

    func viewDidLoad() {
        interactor.requestPermission()

        view?.set(coinName: coin.title)
        view?.set(selectedState: notification.state)
    }

    func didSelect(state: AlertState) {
        guard notification.state != state else {
            return
        }

        notification.state = state

        handleUpdated(alert: notification)
    }

    func didTapSettingsButton() {
        router.openSettings()
    }

}

extension ChartNotificationPresenter: IChartNotificationInteractorDelegate {

    func didGrantPermission() {
        view?.hideWarning()
    }

    func didDenyPermission() {
        view?.showWarning()
    }

    func didEnterForeground() {
        interactor.requestPermission()
    }

    func didFailSaveAlerts(error: Error) {
        notification = interactor.notification(coin: coin)

        view?.set(selectedState: notification.state)

        view?.showError(error: error.convertedError)
    }

}
