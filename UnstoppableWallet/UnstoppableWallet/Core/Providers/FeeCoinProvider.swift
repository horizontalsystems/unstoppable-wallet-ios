class FeeCoinProvider {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    private func binanceFeeCoin(symbol: String) -> Coin? {
        guard symbol != "BNB" else {
            return nil
        }

        return appConfigProvider.defaultCoins.first(where: { coin in
            if case let .binance(symbol) = coin.type {
                return symbol == "BNB"
            }
            return false
        })
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
            return appConfigProvider.ethereumCoin
        case .bep20:
            return appConfigProvider.binanceSmartChainCoin
        case .binance(let symbol):
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
        case .binance(let symbol):
            return binanceFeeCoinProtocol(symbol: symbol)
        default:
            return nil
        }
    }

}
