import MarketKit

class FeeCoinProvider {
    private let marketKit: Kit

    init(marketKit: Kit) {
        self.marketKit = marketKit
    }

    private func binanceFeeCoin(symbol: String) -> PlatformCoin? {
        guard symbol != "BNB" else {
            return nil
        }

        return try? marketKit.platformCoin(coinType: .bep2(symbol: "BNB"))
    }

    private func binanceFeeCoinProtocol(symbol: String) -> String? {
        guard symbol != "BNB" else {
            return nil
        }

        return "BEP2"
    }

}

extension FeeCoinProvider {

    func feeCoin(coinType: CoinType) -> PlatformCoin? {
        switch coinType {
        case .erc20:
            return try? marketKit.platformCoin(coinType: .ethereum)
        case .bep20:
            return try? marketKit.platformCoin(coinType: .binanceSmartChain)
        case .bep2(let symbol):
            return binanceFeeCoin(symbol: symbol)
        default:
            return nil
        }
    }

    func feeCoinProtocol(coinType: CoinType) -> String? {
        switch coinType {
        case .erc20:
            return "ERC20"
        case .bep20:
            return "BEP20"
        case .bep2(let symbol):
            return binanceFeeCoinProtocol(symbol: symbol)
        default:
            return nil
        }
    }

}
