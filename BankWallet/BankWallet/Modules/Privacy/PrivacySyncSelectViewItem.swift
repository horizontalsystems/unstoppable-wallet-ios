struct PrivacySyncSelectViewItem {
    let title: String
    let selected: Bool
    let priority: Priority

    enum Priority {
        case recommended
        case morePrivate
    }
}

