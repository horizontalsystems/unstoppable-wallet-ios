import Foundation
import RxSwift
import RxRelay
import MarketKit
import CurrencyKit

class CoinSelectService {
    private let dex: SwapModule.Dex
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let currencyKit: CurrencyKit.Kit
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private var filter: String = ""

    init(dex: SwapModule.Dex, marketKit: MarketKit.Kit, walletManager: WalletManager, adapterManager: AdapterManager, currencyKit: CurrencyKit.Kit) {
        self.dex = dex
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyKit = currencyKit

        syncItems()
    }

    private func dexSupports(token: Token) -> Bool {
        token.blockchainType == dex.blockchainType
    }

    private func walletItems() -> [Item] {
        let balanceCoins = walletManager.activeWallets.compactMap { wallet -> (token: Token, balance: Decimal)? in
            guard dexSupports(token: wallet.token) else {
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

            return (token: wallet.token, balance: adapter.balanceData.balance)
        }

        return balanceCoins.map { token, balance -> Item in
            let coinPrice: CoinPrice? = marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currencyKit.baseCurrency.code)
            let rate: Decimal? = coinPrice.flatMap { $0.expired ? nil : $0.value }

            return Item(token: token, balance: balance, rate: rate)
        }
    }

    private func coinItems() -> [Item] {
        do {
            let tokens = try marketKit.tokens(blockchainType: dex.blockchainType, filter: filter)

            return tokens.map { token in
                Item(token: token, balance: nil, rate: nil)
            }
        } catch {
            return []
        }
    }

    private func syncItems() {
        let walletItems = walletItems()

        let coinItems = coinItems().filter { coinItem in
            !walletItems.contains { $0.token == coinItem.token }
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

                let lhsExactCode = lhsItem.token.coin.code.lowercased() == filter
                let rhsExactCode = rhsItem.token.coin.code.lowercased() == filter

                if lhsExactCode != rhsExactCode {
                    return lhsExactCode
                }

                let lhsStartsWithCode = lhsItem.token.coin.code.lowercased().starts(with: filter)
                let rhsStartsWithCode = rhsItem.token.coin.code.lowercased().starts(with: filter)

                if lhsStartsWithCode != rhsStartsWithCode {
                    return lhsStartsWithCode
                }

                let lhsStartsWithName = lhsItem.token.coin.name.lowercased().starts(with: filter)
                let rhsStartsWithName = rhsItem.token.coin.name.lowercased().starts(with: filter)

                if lhsStartsWithName != rhsStartsWithName {
                    return lhsStartsWithName
                }
            }

            let lhsMarketCapRank = lhsItem.token.coin.marketCapRank ?? Int.max
            let rhsMarketCapRank = rhsItem.token.coin.marketCapRank ?? Int.max

            if lhsMarketCapRank != rhsMarketCapRank {
                return lhsMarketCapRank < rhsMarketCapRank
            }

            return lhsItem.token.coin.name.lowercased() < rhsItem.token.coin.name.lowercased()
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
        let token: Token
        let balance: Decimal?
        let rate: Decimal?
    }

}
