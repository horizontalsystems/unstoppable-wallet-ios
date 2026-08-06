import Combine
import EvmKit
import Foundation
import HsExtensions
import MarketKit

class MultiSwapTokenSelectViewModel: ObservableObject {
    private static let recentLimit = 10
    private static let topLimit = 25

    private var sectionsTask: AnyTask?
    private var searchTask: AnyTask?

    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
    private let adapterManager = Core.shared.adapterManager
    private let currencyManager = Core.shared.currencyManager
    private let walletManager = Core.shared.walletManager
    private let localStorage = Core.shared.localStorage

    private let token: Token?

    @Published var searchText: String = "" {
        didSet {
            syncSearchResults()
        }
    }

    @Published var searchActive = false

    @Published var popular = [Item]()
    @Published var yourTokens = [Item]()
    @Published var topTokens = [Item]()
    @Published var recent = [Item]()
    @Published var searchResults = [Item]()

    init(token: Token?) {
        self.token = token

        syncSections()
    }

    var searching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // tokens picked while the search field is active are remembered as recent
    func handleSelection(token: Token) {
        guard searchActive || searching else {
            return
        }

        let id = token.tokenQuery.id
        localStorage.swapRecentTokenQueryIds = Array(([id] + localStorage.swapRecentTokenQueryIds.filter { $0 != id }).prefix(Self.recentLimit))
    }

    private func syncSections() {
        let account = accountManager.activeAccount

        sectionsTask = Task { [weak self, marketKit, walletManager, adapterManager, currencyManager, localStorage, token] in
            let wallets = walletManager.activeWallets
            let currency = currencyManager.baseCurrency
            let coinPriceMap = marketKit.coinPriceMap(coinUids: wallets.map(\.coin.uid).removeDuplicates(), currencyCode: currency.code)

            var balances = [Token: Decimal]()
            var coinPrices = [String: Decimal]()

            for wallet in wallets {
                balances[wallet.token] = adapterManager.balanceAdapter(for: wallet)?.balanceData.available ?? 0

                if let coinPrice = coinPriceMap[wallet.coin.uid], !coinPrice.expired {
                    coinPrices[wallet.coin.uid] = coinPrice.value
                }
            }

            let context = TokenSortContext(balances: balances, coinPrices: coinPrices)

            func item(token: Token) -> Item {
                var balanceString: String?
                var fiatBalanceString: String?

                if let balance = balances[token] {
                    balanceString = AppValue(token: token, value: balance).formattedShort()

                    if let price = coinPrices[token.coin.uid] {
                        fiatBalanceString = ValueFormatter.instance.formatShort(currency: currency, value: balance * price)
                    }
                }

                return Item(token: token, balance: balanceString, fiatBalance: fiatBalanceString)
            }

            let popularTokens = MultiSwapPopularTokenResolver.tokens(marketKit: marketKit, for: token)
                .filter { account?.type.supports(token: $0) ?? true }
            let popular = popularTokens.map { Item(token: $0, balance: nil, fiatBalance: nil) }

            let yourTokens = wallets.map(\.token)
                .sorted(by: SortCriterion.walletBalance, context: context)
                .map(item)

            var excludedIds = Set((popularTokens + wallets.map(\.token)).map(\.tokenQuery.id))
            var topTokens = [Item]()

            let topCoins = ((try? marketKit.topFullCoins(limit: 100)) ?? [])
                .sorted { ($0.coin.marketCapRank ?? .max) < ($1.coin.marketCapRank ?? .max) }

            for fullCoin in topCoins {
                if topTokens.count >= Self.topLimit {
                    break
                }

                let eligible = fullCoin.tokens.filter { candidate in
                    (account?.type.supports(token: candidate) ?? true) && BlockchainType.supported.contains(candidate.blockchainType)
                }

                let representative = eligible
                    .sorted(by: [.codeNativeFirst, .blockchainOrder, .badge], context: context)
                    .first { !excludedIds.contains($0.tokenQuery.id) }

                guard let representative else {
                    continue
                }

                excludedIds.insert(representative.tokenQuery.id)
                topTokens.append(item(token: representative))
            }

            let recent = localStorage.swapRecentTokenQueryIds
                .compactMap { TokenQuery(id: $0) }
                .compactMap { (try? marketKit.token(query: $0)) ?? nil }
                .filter { account?.type.supports(token: $0) ?? true }
                .map(item)

            let resolvedTopTokens = topTokens

            guard !Task.isCancelled else {
                return
            }

            await self?.apply(popular: popular, yourTokens: yourTokens, topTokens: resolvedTopTokens, recent: recent)
        }
        .erased()
    }

    @MainActor private func apply(popular: [Item], yourTokens: [Item], topTokens: [Item], recent: [Item]) {
        self.popular = popular
        self.yourTokens = yourTokens
        self.topTokens = topTokens
        self.recent = recent
    }

    @MainActor private func apply(searchResults: [Item]) {
        self.searchResults = searchResults
    }

    private func syncSearchResults() {
        searchTask = nil

        let filter = searchText.trimmingCharacters(in: .whitespaces)

        guard !filter.isEmpty else {
            searchResults = []
            return
        }

        let account = accountManager.activeAccount

        searchTask = Task { [weak self, marketKit, walletManager, adapterManager, currencyManager] in
            let wallets = walletManager.activeWallets
            let currency = currencyManager.baseCurrency
            let coinPriceMap = marketKit.coinPriceMap(coinUids: wallets.map(\.coin.uid).removeDuplicates(), currencyCode: currency.code)

            var balances = [Token: Decimal]()
            var fiatBalances = [Token: Decimal]()

            for wallet in wallets {
                let balance = adapterManager.balanceAdapter(for: wallet)?.balanceData.available ?? 0
                balances[wallet.token] = balance

                if let coinPrice = coinPriceMap[wallet.coin.uid], !coinPrice.expired {
                    fiatBalances[wallet.token] = balance * coinPrice.value
                }
            }

            let context = TokenSortContext(balances: balances, fiatBalances: fiatBalances)
            context.filter = filter
            context.enabledTokens = Set(wallets.map(\.token))

            var resultTokens = [Token]()

            if let ethAddress = try? EvmKit.Address(hex: filter) {
                let tokens = (try? marketKit.tokens(reference: ethAddress.hex)) ?? []

                resultTokens = tokens
                    .filter { (account?.type.supports(token: $0) ?? true) }
                    .sorted(by: SortCriterion.tokenByBlockchain, context: context)
            } else {
                let allFullCoins = (try? marketKit.fullCoins(filter: filter, limit: 100)) ?? []
                let tokens = allFullCoins.map(\.tokens).flatMap { $0 }

                resultTokens = tokens
                    .filter { (account?.type.supports(token: $0) ?? true) }
                    .sorted(by: SortCriterion.tokenFilteredByBlockchain, context: context)
            }

            let items = resultTokens.map { token in
                var balanceString: String?
                var fiatBalanceString: String?

                if let balance = balances[token] {
                    balanceString = AppValue(token: token, value: balance).formattedShort()

                    if let fiatBalance = fiatBalances[token] {
                        fiatBalanceString = ValueFormatter.instance.formatShort(currency: currency, value: fiatBalance)
                    }
                }

                return Item(token: token, balance: balanceString, fiatBalance: fiatBalanceString)
            }

            guard !Task.isCancelled else {
                return
            }

            await self?.apply(searchResults: items)
        }
        .erased()
    }
}

extension MultiSwapTokenSelectViewModel {
    struct Item: Hashable {
        let token: Token
        let balance: String?
        let fiatBalance: String?

        func hash(into hasher: inout Hasher) {
            hasher.combine(token)
        }
    }
}
