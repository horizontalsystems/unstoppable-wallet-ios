import MarketKit

extension TopPlatform: Hashable {
    public static func == (lhs: TopPlatform, rhs: TopPlatform) -> Bool {
        lhs.blockchain.uid == rhs.blockchain.uid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(blockchain.uid)
    }
}

extension TopPlatform: Identifiable {
    public var id: String {
        blockchain.uid
    }
}
