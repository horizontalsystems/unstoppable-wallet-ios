import Foundation
import HSEthereumKit

class Ethereum: Coin {

    private let prefix: String

    init(prefix: String = "") {
        self.prefix = prefix
    }

    override var name: String {
        return "\(prefix)Ethereum"
    }

    override var code: String {
        return "\(prefix)ETH"
    }

}
