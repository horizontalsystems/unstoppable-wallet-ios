import EthereumKit
import MarketKit

enum EvmBlockchain: String {
    case ethereum
    case binanceSmartChain
    case polygon
    case optimism
    case arbitrumOne

    var baseCoinType: CoinType {
        switch self {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        case .polygon: return .polygon
        case .optimism: return .ethereumOptimism
        case .arbitrumOne: return .ethereumArbitrumOne
        }
    }

    func evm20CoinType(address: String) -> CoinType {
        switch self {
        case .ethereum: return .erc20(address: address)
        case .binanceSmartChain: return .bep20(address: address)
        case .polygon: return .mrc20(address: address)
        case .optimism: return .optimismErc20(address: address)
        case .arbitrumOne: return .arbitrumOneErc20(address: address)
        }
    }

    func supports(coinType: CoinType) -> Bool {
        switch (coinType, self) {
        case (.ethereum, .ethereum), (.erc20, .ethereum): return true
        case (.binanceSmartChain, .binanceSmartChain), (.bep20, .binanceSmartChain): return true
        case (.polygon, .polygon), (.mrc20, .polygon): return true
        case (.ethereumOptimism, .optimism), (.optimismErc20, .optimism): return true
        case (.ethereumArbitrumOne, .arbitrumOne), (.arbitrumOneErc20, .arbitrumOne): return true
        default: return false
        }
    }

    var platformType: PlatformType {
        switch self {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        case .polygon: return .polygon
        case .optimism: return .optimism
        case .arbitrumOne: return .arbitrumOne
        }
    }

    var uid: String {
        switch self {
        case .ethereum: return "ethereum"
        case .binanceSmartChain: return "binance-smart-chain"
        case .polygon: return "polygon"
        case .optimism: return "optimism"
        case .arbitrumOne: return "arbitrum-one"
        }
    }

    var name: String {
        switch self {
        case .ethereum: return "Ethereum"
        case .binanceSmartChain: return "Binance Smart Chain"
        case .polygon: return "Polygon"
        case .optimism: return "Optimism"
        case .arbitrumOne: return "Arbitrum One"
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
        case .optimism: return "L2 chain"
        case .arbitrumOne: return "L2 chain"
        }
    }

    var icon24: String {
        switch self {
        case .ethereum: return "ethereum_24"
        case .binanceSmartChain: return "binance_smart_chain_24"
        case .polygon: return "polygon_24"
        case .optimism: return "optimism_24"
        case .arbitrumOne: return "arbitrum_one_24"
        }
    }

    var iconPlain24: String {
        switch self {
        case .ethereum: return "ethereum_trx_24"
        case .binanceSmartChain: return "binance_smart_chain_trx_24"
        case .polygon: return "polygon_trx_24"
        case .optimism: return "optimism_trx_24"
        case .arbitrumOne: return "arbitrum_one_trx_24"
        }
    }

    var eip20Type: String {
        switch self {
        case .ethereum: return "ERC20"
        case .binanceSmartChain: return "BEP20"
        case .polygon: return "POLYGON"
        case .optimism: return "OPTIMISM"
        case .arbitrumOne: return "ARBITRUM"
        }
    }

}
