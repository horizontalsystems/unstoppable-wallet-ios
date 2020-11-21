//import Foundation
//import RxSwift
//import EthereumKit
//
//class SwapTokenManager {
//    private let coinManager: ICoinManager
//    private let walletManager: IWalletManager
//    private let adapterManager: IAdapterManager
//
//    init(coinManager: ICoinManager, walletManager: IWalletManager, adapterManager: IAdapterManager) {
//        self.coinManager = coinManager
//        self.walletManager = walletManager
//        self.adapterManager = adapterManager
//    }
//
//    private func wallet(coin: Coin) -> Wallet? {
//        walletManager.wallets.first { $0.coin == coin }
//    }
//
//    private func balance(coin: Coin, walletItems: [SwapModule.CoinBalanceItem]) -> Decimal? {
//        wallet(coin: coin).flatMap { self.adapterManager.balanceAdapter(for: $0)?.balance }
//    }
//
//    private var walletItems: [SwapModule.CoinBalanceItem] {
//        walletManager.wallets.map { wallet in
//            SwapModule.CoinBalanceItem(coin: wallet.coin, balance: adapterManager.balanceAdapter(for: wallet)?.balance, blockchainType: wallet.coin.type.blockchainType)
//        }
//    }
//
//}
//
//extension SwapTokenManager: ISwapCoinManager {
//
//    func balance(coin: Coin) -> Decimal? {
//        walletItems
//            .first(where: { item in item.coin == coin })?
//            .balance
//    }
//
//    func items(accountCoins: Bool, exclude: [Coin]) -> [SwapModule.CoinBalanceItem] {
//        // add filtration by incoming filters (etc. ethereum, binance and other)
//
//        if accountCoins {                                   // ethereum and erc20 tokens with available balances
//            return walletItems.filter { item in
//                let include = !exclude.contains(item.coin)
//                let zeroBalance = item.balance?.isZero ?? false
//
//                return item.coin.type.swappable && include && !zeroBalance
//            }
//        } else {                                            // ethereum and erc20 tokens registered in app
//            return coinManager.coins
//                    .compactMap { coin in
//                let include = !exclude.contains(coin)
//
//                guard coin.type.swappable && include else {
//                    return nil
//                }
//                return SwapModule.CoinBalanceItem(coin: coin, balance: balance(coin: coin, walletItems: walletItems), blockchainType: coin.type.blockchainType)
//            }
//        }
//    }
//
//    func allowanceSingle(coin: Coin, spenderAddress: Address) -> Single<Decimal> {
//        guard let wallet = wallet(coin: coin),
//              let adapter = adapterManager.adapter(for: wallet) as? IErc20Adapter else {
//            return .error(SendTransactionError.wrongAmount)     // todo: change
//        }
//
//        return adapter.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: .latest)
//    }
//
//}
