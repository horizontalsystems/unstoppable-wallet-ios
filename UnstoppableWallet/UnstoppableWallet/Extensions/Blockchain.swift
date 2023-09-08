import MarketKit

extension Blockchain {
    var shortName: String {
        switch type {
        case .binanceSmartChain: return "BSC"
        default: return name
        }
    }

    func explorerUrl(reference: String?) -> String? {
        // using eip3091url field as it was renamed in MarketKit for further refactoring
        guard let explorerUrl = explorerUrl, let reference = reference else {
            return nil
        }

        return explorerUrl.replacingOccurrences(of: "$ref", with: reference)
    }
}

extension Blockchain: Identifiable {
    public var id: String {
        uid
    }
}
