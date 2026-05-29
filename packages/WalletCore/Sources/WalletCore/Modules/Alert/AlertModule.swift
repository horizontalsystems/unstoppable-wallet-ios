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
    let description: String?
    let selected: Bool
    let disabled: Bool

    init(text: String, description: String? = nil, selected: Bool = false, disabled: Bool = false) {
        self.text = text
        self.description = description
        self.selected = selected
        self.disabled = disabled
    }
}

extension AlertViewItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(description)
        hasher.combine(selected)
        hasher.combine(disabled)
    }
}
