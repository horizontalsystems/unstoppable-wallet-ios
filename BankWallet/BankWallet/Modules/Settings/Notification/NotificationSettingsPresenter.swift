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
    }

    func didSelect(state: AlertState, index: Int) {
        let alert = alerts[index]

        alert.state = state

        // save via interactor

        let viewItems = factory.viewItems(alerts: alerts)
        view?.set(viewItems: viewItems)
    }

}
