class NotificationSettingsPresenter {
    weak var view: INotificationSettingsView?

    private let router: INotificationSettingsRouter
    private let interactor: INotificationSettingsInteractor
    private let factory: NotificationSettingsViewItemFactory

    private var alerts: [PriceAlert] = []

    init(router: INotificationSettingsRouter, interactor: INotificationSettingsInteractor, factory: NotificationSettingsViewItemFactory) {
        self.router = router
        self.interactor = interactor
        self.factory = factory
    }

    private func updateViewItems() {
        view?.set(viewItems: factory.viewItems(alerts: alerts, notificationsOn: interactor.pushNotificationsOn, onTap: onTap), showResetAll: factory.showResetAll(notificationsOn: interactor.pushNotificationsOn, alerts: alerts))
    }

    private func onTap(alert: PriceAlert, mode: NotificationSettingPresentMode) {
        router.openSettings(coinType: alert.coinType, coinTitle: alert.coinTitle, mode: mode)
    }

    private func merge(allAlerts: [PriceAlert]) {
        let updatedAlerts = alerts.compactMap { alert in
            allAlerts.first(where: { newAlert in
                newAlert.coinType == alert.coinType
            })
        }

        alerts = updatedAlerts
    }

}

extension NotificationSettingsPresenter: INotificationSettingsViewDelegate {

    func viewDidLoad() {
        alerts = interactor.activeAlerts

        updateViewItems()
        view?.set(pushNotificationsOn: interactor.pushNotificationsOn)

        if interactor.pushNotificationsOn {
            interactor.requestPermission(needUpdate: false)
        }
    }

    func didTapSettingsButton() {
        router.openSystemSettings()
    }

    func didTapDeactivateAll() {
        interactor.deleteAllAlerts()
    }

    func didToggleNotifications(on: Bool) {
        interactor.pushNotificationsOn = on

        if on {
            interactor.requestPermission(needUpdate: true)
        } else {
            view?.set(pushNotificationsOn: interactor.pushNotificationsOn)
            updateViewItems()

            interactor.updateTopics()
        }
    }

}

extension NotificationSettingsPresenter: INotificationSettingsInteractorDelegate {

    func onAlertsUpdate() {
        merge(allAlerts: interactor.alerts)

        updateViewItems()
    }

    func didGrantPermission(needUpdate: Bool) {
        if needUpdate, interactor.apnsTokenReceived {
            interactor.updateTopics()
        }

        view?.hideWarning()

        view?.set(pushNotificationsOn: interactor.pushNotificationsOn)

        updateViewItems()
    }

    func didDenyPermission() {
        view?.showWarning()

        view?.set(pushNotificationsOn: interactor.pushNotificationsOn)
    }

    func didEnterForeground() {
        if interactor.pushNotificationsOn {
            interactor.requestPermission(needUpdate: false)
        }
    }

    func didSaveAlerts() {
        merge(allAlerts: interactor.alerts)

        updateViewItems()
    }

    func didFailSaveAlerts(error: Error) {
        merge(allAlerts: interactor.alerts)

        updateViewItems()

        view?.showError(error: error.convertedError)
    }

    func didUpdateTopics() {
        updateViewItems()
    }

    func didFailUpdateTopics(error: Error) {
        interactor.pushNotificationsOn = !interactor.pushNotificationsOn

        view?.set(pushNotificationsOn: interactor.pushNotificationsOn)
        updateViewItems()

        view?.showError(error: error.convertedError)
    }

}
