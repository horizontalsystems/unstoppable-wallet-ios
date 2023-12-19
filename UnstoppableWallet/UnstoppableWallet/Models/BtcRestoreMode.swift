enum BtcRestoreMode: String, CaseIterable, Identifiable, Codable {
    case blockchair
    case hybrid
    case blockchain

    var id: Self {
        self
    }
}
