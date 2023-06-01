import MarketKit

extension TokenQuery {

    var customCoinUid: String {
        "custom-\(id)"
    }

    // todo: remove this method
    var isSupported: Bool {
        switch (blockchainType, tokenType) {
        case (.bitcoin, .native): return true
        case (.bitcoinCash, .native): return true
        case (.ecash, .native): return true
        case (.litecoin, .native): return true
        case (.dash, .native): return true
        case (.zcash, .native): return true
        case (.ethereum, .native), (.ethereum, .eip20): return true
        case (.optimism, .native), (.optimism, .eip20): return true
        case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
        case (.gnosis, .native), (.gnosis, .eip20): return true
        case (.fantom, .native), (.fantom, .eip20): return true
        case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
        case (.polygon, .native), (.polygon, .eip20): return true
        case (.avalanche, .native), (.avalanche, .eip20): return true
        case (.binanceChain, .native), (.binanceChain, .bep2): return true
        case (.tron, .native), (.tron, .eip20): return true
        default: return false
        }
    }

}
