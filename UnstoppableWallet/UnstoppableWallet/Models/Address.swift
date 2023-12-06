import BitcoinCore
import MarketKit

open class Address: Equatable {
    let raw: String
    let domain: String?
    let blockchainType: BlockchainType?

    init(raw: String, domain: String? = nil, blockchainType: BlockchainType? = nil) {
        self.raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        self.domain = domain?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.blockchainType = blockchainType
    }

    var title: String {
        domain ?? raw
    }

    public static func == (lhs: Address, rhs: Address) -> Bool {
        lhs.raw == rhs.raw &&
            lhs.domain == rhs.domain && lhs.blockchainType == rhs.blockchainType
    }
}

class BitcoinAddress: Address {
    let mnemonicDerivation: MnemonicDerivation

    init(raw: String, domain: String? = nil, blockchainType: BlockchainType, mnemonicDerivation: MnemonicDerivation) {
        self.mnemonicDerivation = mnemonicDerivation

        super.init(raw: raw, domain: domain, blockchainType: blockchainType)
    }
}
