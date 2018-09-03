import Foundation

class Bitcoin: Coin {

    private let prefix: String

    init(prefix: String = "") {
        self.prefix = prefix
    }

    override var name: String {
        return "\(prefix)Bitcoin"
    }

    override var code: String {
        return "\(prefix)BTC"
    }

}
