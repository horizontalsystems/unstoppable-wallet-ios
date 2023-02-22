import MarketKit

extension Blockchain {

    var shortName: String {
        switch type {
        case .binanceSmartChain: return "BSC"
        default: return name
        }
    }

    func explorerUrl(reference: String?) -> String? {
        guard let explorerUrl = explorerUrl, let reference = reference else {
            return nil
        }

        return explorerUrl.replacingOccurrences(of: "$ref", with: reference)
    }

}
