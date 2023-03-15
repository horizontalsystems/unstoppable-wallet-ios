protocol IAlertView: AnyObject {
    func set(viewItems: [AlertViewItem])
}

protocol IAlertViewDelegate {
    func onLoad()
    func onTapViewItem(index: Int)
}

protocol IAlertRouter {
    func close(completion: (() -> Void)?)
}

struct AlertViewItem {
    let text: String
    let selected: Bool
}
