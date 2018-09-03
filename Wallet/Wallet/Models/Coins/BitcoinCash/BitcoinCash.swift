import Foundation

class BitcoinCash: Coin {

    private let prefix: String

    init(prefix: String = "") {
        self.prefix = prefix
    }

    override var name: String {
        return "\(prefix)Bitcoin Cash"
    }

    override var code: String {
        return "\(prefix)BCH"
    }

}
