import RxSwift
import RxRelay
import CoinKit

class CoinSelectService {
    private let dex: SwapModule.Dex
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let disposeBag = DisposeBag()

    private(set) var items = [Item]()

    init(dex: SwapModule.Dex, coinManager: ICoinManager, walletManager: IWalletManager, adapterManager: IAdapterManager) {
        self.dex = dex
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager

        loadItems()
    }

    private func dexSupports(coin: Coin) -> Bool {
        switch coin.type {
        case .ethereum, .erc20: return dex == .uniswap
        case .binanceSmartChain, .bep20: return dex == .pancake
        default: return false
        }
    }

    private func loadItems() {
        var balanceCoins = walletManager.wallets.compactMap { wallet -> (coin: Coin, balance: Decimal)? in
            guard dexSupports(coin: wallet.coin) else {
                return nil
            }

            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                return nil
            }

            return (coin: wallet.coin, balance: adapter.balance)
        }

        balanceCoins.sort { lhsTuple, rhsTuple in
            lhsTuple.coin.title.lowercased() < rhsTuple.coin.title.lowercased()
        }

        let walletItems = balanceCoins.map { coin, balance in
            Item(coin: coin, balance: balance)
        }

        var remainingCoins = coinManager.coins.filter { coin in
            dexSupports(coin: coin) && !walletItems.contains { $0.coin == coin }
        }

        remainingCoins.sort { lhsCoin, rhsCoin in
            lhsCoin.title.lowercased() < rhsCoin.title.lowercased()
        }

        let coinItems = remainingCoins.map { coin in
            Item(coin: coin, balance: nil)
        }

        items = walletItems + coinItems
    }

}

extension CoinSelectService {

    struct Item {
        let coin: Coin
        let balance: Decimal?
    }

}
