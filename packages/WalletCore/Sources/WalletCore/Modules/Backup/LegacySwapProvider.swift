import MarketKit

enum LegacySwapProvider: String {
    case uniswap = "Uniswap"
    case uniswapV3 = "Uniswap V3"
    case oneInch = "1Inch"
    case pancake = "PancakeSwap"
    case pancakeV3 = "PancakeSwap V3"
    case quickSwap = "QuickSwap"

    var id: String {
        switch self {
        case .uniswap: return "uniswap"
        case .uniswapV3: return "uniswap_v3"
        case .oneInch: return "oneinch"
        case .pancake: return "pancake"
        case .pancakeV3: return "pancake_v3"
        case .quickSwap: return "quickswap"
        }
    }
}

extension BlockchainType {
    var legacySwapProviders: [LegacySwapProvider] {
        switch self {
        case .ethereum: return [.oneInch, .uniswap, .uniswapV3, .pancakeV3]
        case .binanceSmartChain: return [.oneInch, .pancake, .pancakeV3, .uniswapV3]
        case .polygon: return [.oneInch, .quickSwap, .uniswapV3]
        case .avalanche: return [.oneInch]
        case .optimism: return [.oneInch]
        case .arbitrumOne: return [.oneInch, .uniswapV3]
        case .gnosis: return [.oneInch]
        case .fantom: return [.oneInch]
        case .base: return [.oneInch, .uniswap, .uniswapV3]
        case .zkSync: return [.uniswapV3, .pancakeV3]
        case .robinhood: return [.uniswapV3]
        default: return []
        }
    }
}
