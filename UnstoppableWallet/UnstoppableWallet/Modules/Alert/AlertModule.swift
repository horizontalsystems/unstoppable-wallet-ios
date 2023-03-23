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
    let disabled: Bool

    init(text: String, selected: Bool, disabled: Bool = false) {
        self.text = text
        self.selected = selected
        self.disabled = disabled
    }

}
