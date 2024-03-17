struct MultiSwapMainField: Identifiable {
    let title: String
    let description: ActionSheetView.InfoDescription?
    let value: String
    let valueLevel: ValueLevel
    let settingId: String?
    let modified: Bool

    init(title: String, description: ActionSheetView.InfoDescription? = nil, value: String, valueLevel: ValueLevel = .regular, settingId: String? = nil, modified: Bool = false) {
        self.title = title
        self.description = description
        self.value = value
        self.valueLevel = valueLevel
        self.settingId = settingId
        self.modified = modified
    }

    var id: String {
        title
    }
}
