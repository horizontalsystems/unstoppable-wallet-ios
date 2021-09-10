import MarketKit

class ChartNotificationPresenter {
    weak var view: IChartNotificationView?

    private let router: IChartNotificationRouter
    private let interactor: IChartNotificationInteractor
    private let factory: IChartNotificationViewModelFactory
    private let presentMode: NotificationSettingPresentMode

    private var alert: PriceAlert

    private let coinType: CoinType
    private let coinTitle: String

    init?(router: IChartNotificationRouter, interactor: IChartNotificationInteractor, factory: IChartNotificationViewModelFactory, coinType: CoinType, coinTitle: String, presentMode: NotificationSettingPresentMode) {
        self.router = router
        self.interactor = interactor
        self.factory = factory
        self.presentMode = presentMode

        self.coinType = coinType
        self.coinTitle = coinTitle

        guard let priceAlert = interactor.priceAlert(coinType: coinType, coinTitle: coinTitle) else {
            return nil
        }

        alert = priceAlert
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

        view?.set(titleViewModel: factory.titleViewModel(coinTitle: coinTitle))
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
        if let alert = interactor.priceAlert(coinType: coinType, coinTitle: coinTitle) {
            self.alert = alert
        }

        updateView()

        view?.showError(error: error.convertedError)
    }

}
