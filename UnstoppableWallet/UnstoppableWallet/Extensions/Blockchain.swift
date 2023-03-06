import MarketKit

extension Blockchain {

    var shortName: String {
        switch type {
        case .binanceSmartChain: return "BSC"
        default: return name
        }
    }

    func eip20TokenUrl(address: String) -> String? {
        // todo: remove this stub
        switch uid {
        case "ethereum": return "https://etherscan.io/token/\(address)"
        case "binance-smart-chain": return "https://bscscan.com/token/\(address)"
        default: ()
        }

        guard let eip3091url else {
            return nil
        }

        return "\(eip3091url)/token/\(address)"
    }

    func bep2TokenUrl(symbol: String) -> String {
        "https://explorer.binance.org/asset/\(symbol)"
    }

}
