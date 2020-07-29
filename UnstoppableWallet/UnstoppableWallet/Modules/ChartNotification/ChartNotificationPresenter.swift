class ChartNotificationPresenter {
    weak var view: IChartNotificationView?

    private let router: IChartNotificationRouter
    private let interactor: IChartNotificationInteractor
    private let factory: ChartNotificationViewModelFactory

    private var alert: PriceAlert

    private let coin: Coin

    init(router: IChartNotificationRouter, interactor: IChartNotificationInteractor, factory: ChartNotificationViewModelFactory, coin: Coin) {
        self.router = router
        self.interactor = interactor
        self.factory = factory

        self.coin = coin

        self.alert = interactor.priceAlert(coin: coin)
    }

}

extension ChartNotificationPresenter: IChartNotificationViewDelegate {

    func viewDidLoad() {
        interactor.requestPermission()

        view?.set(titleViewModel: factory.titleViewModel(coin: coin))
        view?.set(sectionViewModels: factory.sections(alert: alert))
    }

    func didSelect(alertState: Int, stateIndex: Int) {
        alert.update(alertState: alertState, stateIndex: stateIndex)

        interactor.save(priceAlert: alert)

        view?.set(sectionViewModels: factory.sections(alert: alert))
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

        view?.set(sectionViewModels: factory.sections(alert: alert))

        view?.showError(error: error.convertedError)
    }

}
