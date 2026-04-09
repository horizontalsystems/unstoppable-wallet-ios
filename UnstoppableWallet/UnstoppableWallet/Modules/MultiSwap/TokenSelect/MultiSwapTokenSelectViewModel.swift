import Combine
import EvmKit
import Foundation
import HsExtensions
import MarketKit

class MultiSwapTokenSelectViewModel: ObservableObject {
    private var syncTask: AnyTask?

    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
    private let adapterManager = Core.shared.adapterManager
    private let currencyManager = Core.shared.currencyManager
    private let walletManager = Core.shared.walletManager

    private let token: Token?

    @Published var searchText: String = "" {
        didSet {
            syncItems()
        }
    }

    @Published var items: [Item] = []

    init(token: Token?) {
        self.token = token

        syncItems()
    }

    private func syncItems() {
        syncTask = nil

        let filter = searchText.trimmingCharacters(in: .whitespaces)

        let account = accountManager.activeAccount

        syncTask = Task { [weak self, marketKit, walletManager, adapterManager, currencyManager, token] in
            let wallets = walletManager.activeWallets
            var resultTokens = [Token]()

            let currency = currencyManager.baseCurrency
            let coinPriceMap = marketKit.coinPriceMap(coinUids: wallets.map(\.coin.uid).removeDuplicates(), currencyCode: currency.code)

            var balances = [Token: Decimal]()
            var fiatBalances = [Token: Decimal]()

            for wallet in wallets {
                let balance = adapterManager.balanceAdapter(for: wallet)?.balanceData.available ?? 0
                balances[wallet.token] = balance

                if let coinPrice = coinPriceMap[wallet.coin.uid] {
                    fiatBalances[wallet.token] = balance * coinPrice.value
                }
            }

            let context = TokenSortContext(balances: balances, fiatBalances: fiatBalances)
            context.filter = filter
            context.enabledTokens = Set(wallets.map(\.token))
            context.referenceToken = token

            do {
                if filter.isEmpty {
                    let enabledTokens = wallets.map(\.token).sorted(
                        by: [.sameBlockchainFirst, .fiatBalanceDescending, .codeAscending, .codeNativeFirst, .blockchainOrder, .badge],
                        context: context
                    )
                    resultTokens.append(contentsOf: enabledTokens)

                    if let token {
                        let topFullCoins = try marketKit.topFullCoins(limit: 100)

                        let tokens = topFullCoins
                            .map { $0.tokens.filter { $0.blockchainType == token.blockchainType } }
                            .flatMap { $0 }

                        let suggestedTokens = tokens
                            .filter { (account?.type.supports(token: $0) ?? true) && !resultTokens.contains($0) }
                            .sorted(by: [.marketCapRank, .codeNativeFirst, .blockchainOrder, .badge], context: context)

                        resultTokens.append(contentsOf: suggestedTokens)
                    }

                    let tokenQueries: [TokenQuery]
                    if case .hdExtendedKey = account?.type {
                        tokenQueries = BtcBlockchainManager.blockchainTypes.map(\.nativeTokenQueries).flatMap { $0 }
                    } else {
                        tokenQueries = BlockchainType.supported.map(\.defaultTokenQuery)
                    }

                    let tokens = try marketKit.tokens(queries: tokenQueries)

                    let featuredTokens = tokens
                        .filter { (account?.type.supports(token: $0) ?? true) && !resultTokens.contains($0) }
                        .sorted(by: [.codeNativeFirst, .blockchainOrder, .badge], context: context)

                    resultTokens.append(contentsOf: featuredTokens)
                } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                    let address = ethAddress.hex
                    let tokens = try marketKit.tokens(reference: address)

                    resultTokens = tokens
                        .filter { (account?.type.supports(token: $0) ?? true) }
                        .sorted(by: [.enabled, .codeNativeFirst, .blockchainOrder, .badge], context: context)
                } else {
                    let allFullCoins = try marketKit.fullCoins(filter: filter, limit: 100)
                    let tokens = allFullCoins.map(\.tokens).flatMap { $0 }

                    resultTokens = tokens
                        .filter { (account?.type.supports(token: $0) ?? true) }
                        .sorted(by: [.enabled, .filterRelevance, .codeNativeFirst, .blockchainOrder, .badge], context: context)
                }
            } catch {}

            let items = resultTokens.map { token in
                var balanceString: String?
                var fiatBalanceString: String?

                if let balance = balances[token] {
                    balanceString = AppValue(token: token, value: balance).formattedShort()

                    if let fiatBalance = fiatBalances[token] {
                        fiatBalanceString = ValueFormatter.instance.formatShort(currency: currency, value: fiatBalance)
                    }
                }

                return Item(
                    token: token,
                    balance: balanceString,
                    fiatBalance: fiatBalanceString
                )
            }

            if !Task.isCancelled {
                await MainActor.run { [weak self] in
                    self?.items = items
                }
            }
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
