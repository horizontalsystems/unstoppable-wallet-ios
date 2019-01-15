enum ShowExtra { case none, icon, hash }

struct FullTransactionItem {
    let title: String
    let value: String?

    let clickable: Bool
    let url: String?

    let showExtra: ShowExtra

    init(title: String, value: String?, clickable: Bool = false, url: String? = nil, showExtra: ShowExtra = .none) {
        self.title = title
        self.value = value
        self.clickable = clickable
        self.url = url
        self.showExtra = showExtra
    }

}
