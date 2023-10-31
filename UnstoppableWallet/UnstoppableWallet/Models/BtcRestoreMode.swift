enum BtcRestoreMode: String, CaseIterable, Identifiable, Codable {
    case api
    case blockchain

    var id: Self {
        self
    }
}
