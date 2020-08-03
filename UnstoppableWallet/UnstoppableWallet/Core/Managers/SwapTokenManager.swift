import Foundation

class SwapTokenManager {
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager

    init(coinManager: ICoinManager, walletManager: IWalletManager, adapterManager: IAdapterManager) {
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
    }

    private var walletItems: [CoinBalanceItem] {
        walletManager.wallets.map { wallet in
            CoinBalanceItem(coin: wallet.coin, balance: adapterManager.balanceAdapter(for: wallet)?.balance)
        }
    }

    private func balance(coin: Coin, walletItems: [CoinBalanceItem]) -> Decimal? {
        if let item = walletItems.first(where: { $0.coin == coin }) {
            return item.balance
        }
        return nil
    }

}

extension SwapTokenManager: ISwapCoinManager {

    func balance(coin: Coin) -> Decimal? {
        walletItems
            .first(where: { item in item.coin == coin })?
            .balance
    }

    func items(accountCoins: Bool, exclude: [Coin]) -> [CoinBalanceItem] {
        // add filtration by incoming filters (etc. ethereum, binance and other)

        if accountCoins {                                   // ethereum and erc20 tokens with available balances
            return walletItems.filter { item in
                let include = !exclude.contains(item.coin)
                let zeroBalance = item.balance?.isZero ?? false

                return item.coin.type.swappable && include && !zeroBalance
            }
        } else {                                            // ethereum and erc20 tokens registered in app
            return coinManager.coins
                    .compactMap { coin in
                let include = !exclude.contains(coin)

                guard coin.type.swappable && include else {
                    return nil
                }
                return CoinBalanceItem(coin: coin, balance: balance(coin: coin, walletItems: walletItems))
            }
        }
    }

}
