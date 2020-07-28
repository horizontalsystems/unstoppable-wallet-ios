class ChartNotificationPresenter {
    weak var view: IChartNotificationView?

    private let router: IChartNotificationRouter
    private let interactor: IChartNotificationInteractor

    private var alert: PriceAlert

    private let coin: Coin

    init(router: IChartNotificationRouter, interactor: IChartNotificationInteractor, coin: Coin) {
        self.router = router
        self.interactor = interactor

        self.coin = coin

        self.alert = interactor.priceAlert(coin: coin)
    }

    private func handleUpdated(alert: PriceAlert) {
        interactor.save(priceAlert: alert)

        view?.set(alert: alert)
    }

}

extension ChartNotificationPresenter: IChartNotificationViewDelegate {

    func viewDidLoad() {
        interactor.requestPermission()

        view?.set(coinName: coin.title)
        view?.set(alert: alert)
    }

    func didSelect(changeState: PriceAlert.ChangeState) {
        guard alert.changeState != changeState else {
            return
        }

        alert.changeState = changeState

        handleUpdated(alert: alert)
    }

    func didSelect(trendState: PriceAlert.TrendState) {
        guard alert.trendState != trendState else {
            return
        }

        alert.trendState = trendState

        handleUpdated(alert: alert)
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
        alert = interactor.priceAlert(coin: coin)

        view?.set(alert: alert)

        view?.showError(error: error.convertedError)
    }

}
