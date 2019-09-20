protocol INotificationSettingsView: AnyObject {
    func set(viewItems: [PriceAlertViewItem])
}

protocol INotificationSettingsViewDelegate {
    func viewDidLoad()
    func didSelect(state: AlertState, index: Int)
}

protocol INotificationSettingsInteractor: AnyObject {
    var alerts: [PriceAlert] { get }
}

protocol INotificationSettingsRouter {
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
