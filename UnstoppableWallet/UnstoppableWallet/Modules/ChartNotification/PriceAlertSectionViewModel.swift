struct PriceAlertSectionViewModel {
    let header: String?
    let rows: [Row]

    struct Row {
        let title: String
        let selected: Bool
        let action: (Int) -> ()
    }
}
