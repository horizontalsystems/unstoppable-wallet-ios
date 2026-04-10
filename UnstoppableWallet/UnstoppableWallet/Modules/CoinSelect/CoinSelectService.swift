import Foundation
import MarketKit
import RxRelay
import RxSwift

class CoinSelectService {
    private let dex: SwapModule.Dex
    private let marketKit: MarketKit.Kit
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let currencyManager: CurrencyManager
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private var filter: String = ""

    init(dex: SwapModule.Dex, marketKit: MarketKit.Kit, walletManager: WalletManager, adapterManager: AdapterManager, currencyManager: CurrencyManager) {
        self.dex = dex
        self.marketKit = marketKit
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager

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

            return (token: wallet.token, balance: adapter.balanceData.available)
        }

        return balanceCoins.map { token, balance -> Item in
            let coinPrice: CoinPrice? = marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currencyManager.baseCurrency.code)
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

        let context = TokenSortContext()
        context.filter = filter
        context.enabledTokens = Set(walletItems.map(\.token))
        for item in walletItems {
            if let balance = item.balance {
                context.balances[item.token] = balance
            }
        }

        let criteria = filter.isEmpty
            ? SortCriterion.coinSelect
            : SortCriterion.coinSelectFiltered

        items = allItems.sorted(by: criteria, context: context)
    }
}

extension CoinSelectService {
    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var currency: Currency {
        currencyManager.baseCurrency
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

extension CoinSelectService.Item: IComposableSortable {
    typealias Context = TokenSortContext

    static func compare(_ lhs: CoinSelectService.Item, _ rhs: CoinSelectService.Item, by criterion: SortCriterion, context: TokenSortContext) -> ComparisonResult {
        Token.compare(lhs.token, rhs.token, by: criterion, context: context)
    }
}
