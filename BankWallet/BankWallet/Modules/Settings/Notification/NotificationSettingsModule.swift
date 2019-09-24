protocol INotificationSettingsView: AnyObject {
    func set(viewItems: [PriceAlertViewItem])
    func showWarning()
    func hideWarning()
}

protocol INotificationSettingsViewDelegate {
    func viewDidLoad()
    func didSelect(state: AlertState, index: Int)
    func didTapSettingsButton()
}

protocol INotificationSettingsInteractor {
    var alerts: [PriceAlert] { get }
    func requestPermission()
    func save(priceAlert: PriceAlert)
}

protocol INotificationSettingsInteractorDelegate: AnyObject {
    func didGrantPermission()
    func didDenyPermission()
    func didEnterForeground()
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
