public struct AlertViewItem {
    let text: String
    let description: String?
    let selected: Bool
    let disabled: Bool
    let identifier: String?

    public init(text: String, description: String? = nil, selected: Bool = false, disabled: Bool = false, identifier: String? = nil) {
        self.text = text
        self.description = description
        self.selected = selected
        self.disabled = disabled
        self.identifier = identifier
    }
}

extension AlertViewItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(description)
        hasher.combine(selected)
        hasher.combine(disabled)
        hasher.combine(identifier)
    }
}
