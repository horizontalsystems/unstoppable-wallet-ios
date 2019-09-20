class NotificationSettingsInteractor {
    private let priceAlertManager: IPriceAlertManager

    init(priceAlertManager: IPriceAlertManager) {
        self.priceAlertManager = priceAlertManager
    }

}

extension NotificationSettingsInteractor: INotificationSettingsInteractor {

    var alerts: [PriceAlert] {
        return priceAlertManager.priceAlerts
    }

    func save(priceAlert: PriceAlert) {
        priceAlertManager.save(priceAlert: priceAlert)
    }

}
