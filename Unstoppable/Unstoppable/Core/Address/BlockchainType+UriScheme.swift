import MarketKit

extension BlockchainType {
    var uriScheme: String? {
        if isEvm { return "ethereum" }
        switch self {
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoincash"
        case .ecash: return "ecash"
        case .litecoin: return "litecoin"
        case .dash: return "dash"
        case .zcash: return "zcash"
        case .tron: return "tron"
        case .ton: return "ton"
        case .monero: return "monero"
        case .zano: return "zano"
        case .stellar: return "stellar"
        case .solana: return "solana"
        default: return nil
        }
    }

    // BCH/eCash keep the scheme prefix as part of the canonical address form;
    // everything else strips it.
    var removeScheme: Bool {
        if isEvm { return true }
        switch self {
        case .bitcoin, .litecoin, .dash, .zcash, .tron, .ton, .monero, .zano, .stellar, .solana: return true
        case .bitcoinCash, .ecash: return false
        default: return false
        }
    }

    func uriPath(address: String) -> String {
        if let chain = try? Core.shared.evmBlockchainManager.chain(blockchainType: self) {
            return [address, chain.id.description].joined(separator: "@")
        }
        return address
    }
}
