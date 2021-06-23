import RxSwift
import RxRelay
import CoinKit
import CurrencyKit
import XRatesKit

class CoinSelectService {
    private let dex: SwapModuleNew.DexNew
    private let coinManager: ICoinManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let rateManager: IRateManager
    private let currencyKit: CurrencyKit.Kit

    private let disposeBag = DisposeBag()

    private(set) var items = [Item]()

    init(dex: SwapModuleNew.DexNew, coinManager: ICoinManager, walletManager: WalletManager, adapterManager: AdapterManager, rateManager: IRateManager, currencyKit: CurrencyKit.Kit) {
        self.dex = dex
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.rateManager = rateManager
        self.currencyKit = currencyKit

        loadItems()
    }

    private func dexSupports(coin: Coin) -> Bool {
        switch coin.type {
        case .ethereum, .erc20: return dex.blockchain == .ethereum
        case .binanceSmartChain, .bep20: return dex.blockchain == .binanceSmartChain
        default: return false
        }
    }

    private func loadItems() {
        var balanceCoins = walletManager.activeWallets.compactMap { wallet -> (coin: Coin, balance: Decimal)? in
            guard dexSupports(coin: wallet.coin) else {
                return nil
            }

            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                return nil
            }

            return (coin: wallet.coin, balance: adapter.balanceData.balance)
        }

        balanceCoins.sort { lhsTuple, rhsTuple in
            lhsTuple.coin.title.lowercased() < rhsTuple.coin.title.lowercased()
        }

        let walletItems = balanceCoins.map { coin, balance -> Item in
            let latestRate: LatestRate? = rateManager.latestRate(coinType: coin.type, currencyCode: currencyKit.baseCurrency.code)
            let rate: Decimal? = latestRate.flatMap { $0.expired ? nil : $0.rate }

            return Item(coin: coin, balance: balance, rate: rate)
        }

        var remainingCoins = coinManager.coins.filter { coin in
            dexSupports(coin: coin) && !walletItems.contains { $0.coin == coin }
        }

        remainingCoins.sort { lhsCoin, rhsCoin in
            lhsCoin.title.lowercased() < rhsCoin.title.lowercased()
        }

        let coinItems = remainingCoins.map { coin in
            Item(coin: coin, balance: nil, rate: nil)
        }

        items = walletItems + coinItems
    }

}

extension CoinSelectService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

}

extension CoinSelectService {

    struct Item {
        let coin: Coin
        let balance: Decimal?
        let rate: Decimal?
    }

}
