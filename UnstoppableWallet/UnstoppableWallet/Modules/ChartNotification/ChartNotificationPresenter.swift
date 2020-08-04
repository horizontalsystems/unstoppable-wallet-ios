class ChartNotificationPresenter {
    weak var view: IChartNotificationView?

    private let router: IChartNotificationRouter
    private let interactor: IChartNotificationInteractor
    private let factory: IChartNotificationViewModelFactory
    private let presentMode: NotificationSettingPresentMode

    private var alert: PriceAlert

    private let coin: Coin

    init(router: IChartNotificationRouter, interactor: IChartNotificationInteractor, factory: IChartNotificationViewModelFactory, coin: Coin, presentMode: NotificationSettingPresentMode) {
        self.router = router
        self.interactor = interactor
        self.factory = factory
        self.presentMode = presentMode

        self.coin = coin

        self.alert = interactor.priceAlert(coin: coin)
    }

    private func updatePriceChange(index: Int) {
        alert.updatePriceChange(stateIndex: index)

        interactor.save(priceAlert: alert)

        updateView()
    }

    private func updateTrend(index: Int) {
        alert.updateTrend(stateIndex: index)

        interactor.save(priceAlert: alert)

        updateView()
    }

    private func updateView() {
        view?.set(sectionViewModels: factory.sections(alert: alert, priceChangeUpdate: { [weak self] index in
            self?.updatePriceChange(index: index)
        }, trendUpdate: { [weak self] index in
            self?.updateTrend(index: index)
        }))
    }

}

extension ChartNotificationPresenter: IChartNotificationViewDelegate {

    func viewDidLoad() {
        interactor.requestPermission()

        view?.set(titleViewModel: factory.titleViewModel(coin: coin))
        updateView()
        view?.set(spacerMode: presentMode)
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

        updateView()

        view?.showError(error: error.convertedError)
    }

}
