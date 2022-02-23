import EthereumKit
import MarketKit

enum EvmBlockchain: String {
    case ethereum
    case binanceSmartChain

    var baseCoinType: CoinType {
        switch self {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        }
    }

    func evm20CoinType(address: String) -> CoinType {
        switch self {
        case .ethereum: return .erc20(address: address)
        case .binanceSmartChain: return .bep20(address: address)
        }
    }

    func supports(coinType: CoinType) -> Bool {
        switch (coinType, self) {
        case (.ethereum, .ethereum), (.erc20, .ethereum): return true
        case (.binanceSmartChain, .binanceSmartChain), (.bep20, .binanceSmartChain): return true
        default: return false
        }
    }

    var name: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .binanceSmartChain: return "Binance Smart Chain"
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
        }
    }

    var icon24: String {
        switch self {
        case .ethereum: return "ethereum_24"
        case .binanceSmartChain: return "binance_smart_chain_24"
        }
    }

    var isMainNet: Bool {
        switch self {
        case .ethereum: return true
        case .binanceSmartChain: return true
        }
    }

}
