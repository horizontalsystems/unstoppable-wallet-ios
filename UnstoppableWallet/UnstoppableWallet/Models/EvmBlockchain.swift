import EthereumKit
import MarketKit

enum EvmBlockchain: String {
    case ethereum
    case binanceSmartChain
    case polygon

    var baseCoinType: CoinType {
        switch self {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        case .polygon: return .polygon
        }
    }

    func evm20CoinType(address: String) -> CoinType {
        switch self {
        case .ethereum: return .erc20(address: address)
        case .binanceSmartChain: return .bep20(address: address)
        case .polygon: return .mrc20(address: address)
        }
    }

    func supports(coinType: CoinType) -> Bool {
        switch (coinType, self) {
        case (.ethereum, .ethereum), (.erc20, .ethereum): return true
        case (.binanceSmartChain, .binanceSmartChain), (.bep20, .binanceSmartChain): return true
        case (.polygon, .polygon), (.mrc20, .polygon): return true
        default: return false
        }
    }

    var uid: String {
        switch self {
        case .ethereum: return "ethereum"
        case .binanceSmartChain: return "binance-smart-chain"
        case .polygon: return "polygon"
        }
    }

    var name: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .binanceSmartChain: return "Binance Smart Chain"
        case .polygon: return "Polygon"
        }
    }

    var shortName: String {
        switch self {
        case .binanceSmartChain: return "BSC"
        default: return name
        }
    }

    var description: String {
        switch self {
        case .ethereum: return "ETH, ERC20 tokens"
        case .binanceSmartChain: return "BNB, BEP20 tokens"
        case .polygon: return "MATIC, MRC20 tokens"
        }
    }

    var icon24: String {
        switch self {
        case .ethereum: return "ethereum_24"
        case .binanceSmartChain: return "binance_smart_chain_24"
        case .polygon: return "polygon_24"
        }
    }

}
