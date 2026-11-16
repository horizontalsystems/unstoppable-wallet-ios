public struct AlertViewItem {
    let text: String
    let selected: Bool
    let identifier: String?

    public init(text: String, selected: Bool = false, identifier: String? = nil) {
        self.text = text
        self.selected = selected
        self.identifier = identifier
    }
}

extension AlertViewItem: Hashable {}
