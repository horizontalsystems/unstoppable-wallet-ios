protocol INotificationSettingsView: AnyObject {
    func set(viewItems: [PriceAlertViewItem])
    func showWarning()
    func hideWarning()
    func showError(error: Error)
}

protocol INotificationSettingsViewDelegate {
    func viewDidLoad()
    func didSelect(state: AlertState, index: Int)
    func didTapSettingsButton()
    func didTapDeactivateAll()
}

protocol INotificationSettingsInteractor {
    var alerts: [PriceAlert] { get }
    func requestPermission()
    func save(priceAlerts: [PriceAlert])
}

protocol INotificationSettingsInteractorDelegate: AnyObject {
    func didGrantPermission()
    func didDenyPermission()
    func didEnterForeground()
    func didFailSaveAlerts(error: Error)
}

protocol INotificationSettingsRouter {
    func openSettings()
}

struct PriceAlertViewItem {
    let title: String
    let code: String
    let state: AlertState
}

struct PriceAlertValueViewItem {
    let value: Int?
    let selected: Bool
}
