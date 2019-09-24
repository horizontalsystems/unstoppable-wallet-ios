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

        alert.state = state

        interactor.save(priceAlert: alert)

        let viewItems = factory.viewItems(alerts: alerts)
        view?.set(viewItems: viewItems)
    }

    func didTapSettingsButton() {
        router.openSettings()
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

}
