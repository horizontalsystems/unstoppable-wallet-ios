import MarketKit

enum BtcRestoreMode: String, CaseIterable, Identifiable, Codable {
    case blockchair
    case hybrid
    case blockchain

    var id: Self {
        self
    }

    func title(blockchain: Blockchain) -> String {
        switch self {
        case .blockchair: return "Blockchair API"
        case .hybrid: return "sync_mode.hybrid".localized
        case .blockchain: return "sync_mode.from_blockchain".localized(blockchain.name)
        }
    }
}
