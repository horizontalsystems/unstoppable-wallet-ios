import MarketKit

extension Blockchain {

    var shortName: String {
        switch type {
        case .binanceSmartChain: return "BSC"
        default: return name
        }
    }

}
