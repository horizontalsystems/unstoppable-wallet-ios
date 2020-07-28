class NotificationSettingsPresenter {
    weak var view: INotificationSettingsView?

    private let router: INotificationSettingsRouter
    private let interactor: INotificationSettingsInteractor
    private let factory = PriceAlertViewItemFactory()

    private var alerts: [PriceAlert] = []

    init(router: INotificationSettingsRouter, interactor: INotificationSettingsInteractor) {
        self.router = router
        self.interactor = interactor
    }

    private func handleUpdated(alerts: [PriceAlert]) {
        interactor.save(priceAlerts: alerts)

        let viewItems = factory.viewItems(alerts: self.alerts)
        view?.set(viewItems: viewItems)
    }

}

extension NotificationSettingsPresenter: INotificationSettingsViewDelegate {

    func viewDidLoad() {
        alerts = interactor.alerts

        let viewItems = factory.viewItems(alerts: alerts)
        view?.set(viewItems: viewItems)

        interactor.requestPermission()
    }

    func didSelect(changeState: PriceAlert.ChangeState, trendState: PriceAlert.TrendState, index: Int) {
        var alert = alerts[index]

        guard alert.changeState != changeState || alert.trendState != trendState else {
            return
        }

        alert.changeState = changeState
        alert.trendState = trendState

        handleUpdated(alerts: [alert])
    }

    func didTapSettingsButton() {
        router.openSettings()
    }

    func didTapDeactivateAll() {
        interactor.deleteAllAlerts()
    }

}

extension NotificationSettingsPresenter: INotificationSettingsInteractorDelegate {

    func didGrantPermission() {
        view?.hideWarning()
    }

    func didDenyPermission() {
        view?.showWarning()
    }

    func didEnterForeground() {
        interactor.requestPermission()
    }

    func didSaveAlerts() {
        alerts = interactor.alerts

        let viewItems = factory.viewItems(alerts: alerts)
        view?.set(viewItems: viewItems)
    }

    func didFailSaveAlerts(error: Error) {
        alerts = interactor.alerts

        let viewItems = factory.viewItems(alerts: alerts)
        view?.set(viewItems: viewItems)

        view?.showError(error: error.convertedError)
    }

}
