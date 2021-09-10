import MarketKit

protocol INotificationSettingsView: AnyObject {
    func set(pushNotificationsOn: Bool)
    func set(viewItems: [NotificationSettingSectionViewItem], showResetAll: Bool)

    func showWarning()
    func hideWarning()
    func showError(error: Error)
}

protocol INotificationSettingsViewDelegate {
    func viewDidLoad()
    func didToggleNotifications(on: Bool)
    func didTapSettingsButton()
    func didTapDeactivateAll()
}

protocol INotificationSettingsInteractor: AnyObject {
    var alerts: [PriceAlert] { get }
    var activeAlerts: [PriceAlert] { get }
    var pushNotificationsOn: Bool { get set }
    var apnsTokenReceived: Bool { get }
    func updateTopics()
    func requestPermission(needUpdate: Bool)
    func deleteAllAlerts()
}

protocol INotificationSettingsInteractorDelegate: AnyObject {
    func onAlertsUpdate()

    func didGrantPermission(needUpdate: Bool)
    func didDenyPermission()
    func didEnterForeground()
    func didSaveAlerts()
    func didFailSaveAlerts(error: Error)
    func didUpdateTopics()
    func didFailUpdateTopics(error: Error)
}

protocol INotificationSettingsRouter {
    func openSystemSettings()
    func openSettings(coinType: CoinType, coinTitle: String, mode: NotificationSettingPresentMode)
}

struct PriceAlertViewItem {
    let title: String
    let code: String
    let changeState: PriceAlert.ChangeState
    let trendState: PriceAlert.TrendState
}

struct PriceAlertValueViewItem {
    let value: Int?
    let selected: Bool
}

struct NotificationSettingSectionViewItem {
    let title: String
    let rowItems: [NotificationSettingRowViewItem]
}

struct NotificationSettingRowViewItem {
    let title: String
    let value: String
    let onTap: () -> ()
}
