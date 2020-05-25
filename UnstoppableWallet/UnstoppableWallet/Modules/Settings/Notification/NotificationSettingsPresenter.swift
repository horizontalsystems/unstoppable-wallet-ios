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

    func didSelect(state: AlertState, index: Int) {
        let alert = alerts[index]

        guard alert.state != state else {
            return
        }

        alert.state = state

        handleUpdated(alerts: [alert])
    }

    func didTapSettingsButton() {
        router.openSettings()
    }

    func didTapDeactivateAll() {
        let activeAlerts = alerts.filter { $0.state != .off }

        activeAlerts.forEach { alert in
            alert.state = .off
        }

        handleUpdated(alerts: activeAlerts)
    }

}

extension NotificationSettingsPresenter: INotificationSettingsInteractorDelegate {

    func didGrantPermission() {
        guard interactor.allowedBackgroundFetching else {
            view?.showWarning()
            return
        }

        view?.hideWarning()
    }

    func didDenyPermission() {
        view?.showWarning()
    }

    func didEnterForeground() {
        interactor.requestPermission()
    }

}
