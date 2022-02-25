import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinSelectService {
    private let dex: SwapModule.Dex
    private let coinManager: CoinManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private var filter: String = ""

    init(dex: SwapModule.Dex, coinManager: CoinManager, walletManager: WalletManager, adapterManager: AdapterManager, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit) {
        self.dex = dex
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        syncItems()
    }

    private func dexSupports(platformCoin: PlatformCoin) -> Bool {
        dex.blockchain.supports(coinType: platformCoin.coinType)
    }

    private func platformType() -> PlatformType {
        switch dex.blockchain {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        case .polygon: return .polygon
        }
    }

    private func walletItems() -> [Item] {
        let balanceCoins = walletManager.activeWallets.compactMap { wallet -> (platformCoin: PlatformCoin, balance: Decimal)? in
            guard dexSupports(platformCoin: wallet.platformCoin) else {
                return nil
            }

            if !filter.isEmpty {
                guard wallet.coin.name.localizedCaseInsensitiveContains(filter) || wallet.coin.code.localizedCaseInsensitiveContains(filter) else {
                    return nil
                }
            }

            guard let adapter = adapterManager.balanceAdapter(for: wallet) else {
                return nil
            }

            return (platformCoin: wallet.platformCoin, balance: adapter.balanceData.balance)
        }

        return balanceCoins.map { platformCoin, balance -> Item in
            let coinPrice: CoinPrice? = marketKit.coinPrice(coinUid: platformCoin.coin.uid, currencyCode: currencyKit.baseCurrency.code)
            let rate: Decimal? = coinPrice.flatMap { $0.expired ? nil : $0.value }

            return Item(platformCoin: platformCoin, balance: balance, rate: rate)
        }
    }

    private func coinItems() -> [Item] {
        do {
            let platformCoins = try coinManager.platformCoins(platformType: platformType(), filter: filter)

            return platformCoins.map { platformCoin in
                Item(platformCoin: platformCoin, balance: nil, rate: nil)
            }
        } catch {
            return []
        }
    }

    private func syncItems() {
        let walletItems = walletItems()

        let coinItems = coinItems().filter { coinItem in
            !walletItems.contains { $0.platformCoin == coinItem.platformCoin }
        }

        let allItems = walletItems + coinItems

        items = allItems.sorted { lhsItem, rhsItem in
            if let lhsBalance = lhsItem.balance, let rhsBalance = rhsItem.balance, lhsBalance != rhsBalance {
                return lhsBalance > rhsBalance
            }

            let lhsHasBalance = lhsItem.balance != nil
            let rhsHasBalance = rhsItem.balance != nil

            if lhsHasBalance != rhsHasBalance {
                return lhsHasBalance
            }

            if !filter.isEmpty {
                let filter = filter.lowercased()

                let lhsExactCode = lhsItem.platformCoin.coin.code.lowercased() == filter
                let rhsExactCode = rhsItem.platformCoin.coin.code.lowercased() == filter

                if lhsExactCode != rhsExactCode {
                    return lhsExactCode
                }

                let lhsStartsWithCode = lhsItem.platformCoin.coin.code.lowercased().starts(with: filter)
                let rhsStartsWithCode = rhsItem.platformCoin.coin.code.lowercased().starts(with: filter)

                if lhsStartsWithCode != rhsStartsWithCode {
                    return lhsStartsWithCode
                }

                let lhsStartsWithName = lhsItem.platformCoin.coin.name.lowercased().starts(with: filter)
                let rhsStartsWithName = rhsItem.platformCoin.coin.name.lowercased().starts(with: filter)

                if lhsStartsWithName != rhsStartsWithName {
                    return lhsStartsWithName
                }
            }

            let lhsMarketCapRank = lhsItem.platformCoin.coin.marketCapRank ?? Int.max
            let rhsMarketCapRank = rhsItem.platformCoin.coin.marketCapRank ?? Int.max

            if lhsMarketCapRank != rhsMarketCapRank {
                return lhsMarketCapRank < rhsMarketCapRank
            }

            return lhsItem.platformCoin.coin.name.lowercased() < rhsItem.platformCoin.coin.name.lowercased()
        }
    }

}

extension CoinSelectService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func set(filter: String) {
        self.filter = filter

        syncItems()
    }

}

extension CoinSelectService {

    struct Item {
        let platformCoin: PlatformCoin
        let balance: Decimal?
        let rate: Decimal?
    }

}
