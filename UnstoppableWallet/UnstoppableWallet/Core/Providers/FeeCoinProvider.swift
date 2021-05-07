import CoinKit

class FeeCoinProvider {
    private let coinKit: CoinKit.Kit

    init(coinKit: CoinKit.Kit) {
        self.coinKit = coinKit
    }

    private func binanceFeeCoin(symbol: String) -> Coin? {
        guard symbol != "BNB" else {
            return nil
        }

        return coinKit.coin(type: .bep2(symbol: "BNB"))
    }

    private func binanceFeeCoinProtocol(symbol: String) -> String? {
        guard symbol != "BNB" else {
            return nil
        }

        return "BEP2"
    }

}

extension FeeCoinProvider: IFeeCoinProvider {

    func feeCoin(coin: Coin) -> Coin? {
        switch coin.type {
        case .erc20:
            return coinKit.coin(type: .ethereum)
        case .bep20:
            return coinKit.coin(type: .binanceSmartChain)
        case .bep2(let symbol):
            return binanceFeeCoin(symbol: symbol)
        default:
            return nil
        }
    }

    func feeCoinProtocol(coin: Coin) -> String? {
        switch coin.type {
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
