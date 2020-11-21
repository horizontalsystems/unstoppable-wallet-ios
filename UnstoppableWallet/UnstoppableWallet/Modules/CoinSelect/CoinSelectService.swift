import RxSwift
import RxRelay

class CoinSelectService {
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let disposeBag = DisposeBag()

    private(set) var items = [Item]()

    init(coinManager: ICoinManager, walletManager: IWalletManager, adapterManager: IAdapterManager) {
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager

        loadItems()
    }

    private func loadItems() {
        var balanceCoins = walletManager.wallets.compactMap { wallet -> (coin: Coin, balance: Decimal)? in
            guard wallet.coin.type.swappable else {
                return nil
            }

            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                return nil
            }

            return (coin: wallet.coin, balance: adapter.balance)
        }

        balanceCoins.sort { tuple, tuple2 in
            tuple.balance > tuple2.balance
        }

        let walletItems = balanceCoins.map { coin, balance in
            Item(coin: coin, balance: balance, blockchainType: coin.type.blockchainType)
        }

        let remainingCoins = coinManager.coins.filter { coin in
            coin.type.swappable && !walletItems.contains { $0.coin == coin }
        }

        let coinItems = remainingCoins.map { coin in
            Item(coin: coin, balance: nil, blockchainType: coin.type.blockchainType)
        }

        items = walletItems + coinItems
    }

}

extension CoinSelectService {

    struct Item {
        let coin: Coin
        let balance: Decimal?
        let blockchainType: String?
    }

}
