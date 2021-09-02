import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinSelectService {
    private let dex: SwapModule.Dex
    private let coinManager: CoinManagerNew
    private let walletManager: WalletManagerNew
    private let adapterManager: AdapterManagerNew
    private let rateManager: RateManagerNew
    private let currencyKit: CurrencyKit.Kit

    private let disposeBag = DisposeBag()

    private(set) var items = [Item]()

    init(dex: SwapModule.Dex, coinManager: CoinManagerNew, walletManager: WalletManagerNew, adapterManager: AdapterManagerNew, rateManager: RateManagerNew, currencyKit: CurrencyKit.Kit) {
        self.dex = dex
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.rateManager = rateManager
        self.currencyKit = currencyKit

        loadItems()
    }

    private func dexSupports(platformCoin: PlatformCoin) -> Bool {
        switch platformCoin.coinType {
        case .ethereum, .erc20: return dex.blockchain == .ethereum
        case .binanceSmartChain, .bep20: return dex.blockchain == .binanceSmartChain
        default: return false
        }
    }

    private func loadItems() {
        var balanceCoins = walletManager.activeWallets.compactMap { wallet -> (platformCoin: PlatformCoin, balance: Decimal)? in
            guard dexSupports(platformCoin: wallet.platformCoin) else {
                return nil
            }

            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                return nil
            }

            return (platformCoin: wallet.platformCoin, balance: adapter.balanceData.balance)
        }

        balanceCoins.sort { lhsTuple, rhsTuple in
            lhsTuple.platformCoin.coin.name.lowercased() < rhsTuple.platformCoin.coin.name.lowercased()
        }

        let walletItems = balanceCoins.map { platformCoin, balance -> Item in
            let latestRate: RateManagerNew.LatestRate? = rateManager.latestRate(coinType: platformCoin.coinType, currencyCode: currencyKit.baseCurrency.code)
            let rate: Decimal? = latestRate.flatMap { $0.expired ? nil : $0.rate }

            return Item(platformCoin: platformCoin, balance: balance, rate: rate)
        }

        let platformCoins: [PlatformCoin] = (try? coinManager.platformCoins()) ?? []

        var remainingCoins = platformCoins.filter { platformCoin in
            dexSupports(platformCoin: platformCoin) && !walletItems.contains { $0.platformCoin == platformCoin }
        }

        remainingCoins.sort { lhsPlatformCoin, rhsPlatformCoin in
            lhsPlatformCoin.coin.name.lowercased() < rhsPlatformCoin.coin.name.lowercased()
        }

        let coinItems = remainingCoins.map { platformCoin in
            Item(platformCoin: platformCoin, balance: nil, rate: nil)
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
        let platformCoin: PlatformCoin
        let balance: Decimal?
        let rate: Decimal?
    }

}
