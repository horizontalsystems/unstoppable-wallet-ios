import Foundation

class Bitcoin: Coin {

    private let networkSuffix: String?

    init(networkSuffix: String? = nil) {
        self.networkSuffix = networkSuffix
    }

    override var name: String {
        if let suffix = networkSuffix {
            return "Bitcoin-\(suffix)"
        }
        return "Bitcoin"
    }

    override var code: String {
        if let suffix = networkSuffix {
            return "BTC-\(suffix)"
        }
        return "BTC"
    }

}
