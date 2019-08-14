class FeeCoinProvider {
    private let appConfigProvider: IAppConfigProvider

    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }

    func feeCoinData(coin: Coin) -> (Coin, String)? {
        switch coin.type {
        case .erc20:
            return erc20()
        case .binance(let symbol):
            return binance(symbol: symbol)
        default:
            return nil
        }
    }

    private func erc20() -> (Coin, String)? {
        guard let coin = appConfigProvider.coins.first(where: { $0.type == .ethereum }) else {
            return nil
        }

        return (coin, "ERC20")
    }

    private func binance(symbol: String) -> (Coin, String)? {
        guard symbol != "BNB" else {
            return nil
        }

        guard let coin = appConfigProvider.coins.first(where: { coin in
            if case let .binance(symbol) = coin.type {
                return symbol == "BNB"
            }
            return false
        }) else {
            return nil
        }

        return (coin, "BEP-2")
    }

}
