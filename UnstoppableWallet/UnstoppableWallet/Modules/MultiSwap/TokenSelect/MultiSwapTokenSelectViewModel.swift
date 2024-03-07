import Combine
import EvmKit
import HsExtensions
import MarketKit

class MultiSwapTokenSelectViewModel: ObservableObject {
    private var syncTask: AnyTask?

    private let marketKit = App.shared.marketKit
    private let accountManager = App.shared.accountManager
    private let adapterManager = App.shared.adapterManager
    private let currencyManager = App.shared.currencyManager
    private let walletManager = App.shared.walletManager

    @Published var searchText: String = "" {
        didSet {
            syncItems()
        }
    }

    @Published var items: [Item] = []

    init() {
        syncItems()
    }

    private func syncItems() {
        syncTask = nil

        let filter = searchText.trimmingCharacters(in: .whitespaces)

        guard let account = accountManager.activeAccount else {
            items = []
            return
        }

        syncTask = Task { [weak self, marketKit, walletManager, adapterManager, currencyManager] in
            let wallets = walletManager.activeWallets
            let resultTokens: [Token]

            do {
                if filter.isEmpty {
                    let tokenQueries: [TokenQuery]
                    if case .hdExtendedKey = account.type {
                        tokenQueries = BtcBlockchainManager.blockchainTypes.map(\.nativeTokenQueries).flatMap { $0 }
                    } else {
                        tokenQueries = BlockchainType.supported.map(\.defaultTokenQuery)
                    }

                    let tokens = try marketKit.tokens(queries: tokenQueries)
                    let featuredTokens = tokens.filter { account.type.supports(token: $0) }
                    let enabledTokens = wallets.map(\.token)

                    resultTokens = (enabledTokens + featuredTokens).removeDuplicates()
                } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                    let address = ethAddress.hex
                    let tokens = try marketKit.tokens(reference: address)

                    resultTokens = tokens.filter { account.type.supports(token: $0) }
                } else {
                    let allFullCoins = try marketKit.fullCoins(filter: filter, limit: 100)
                    let tokens = allFullCoins.map(\.tokens).flatMap { $0 }

                    resultTokens = tokens.filter { account.type.supports(token: $0) }
                }
            } catch {
                resultTokens = []
            }

            let sortedResult = resultTokens.sorted { lhsToken, rhsToken in
                let lhsEnabled = wallets.contains { $0.token == lhsToken }
                let rhsEnabled = wallets.contains { $0.token == rhsToken }

                if lhsEnabled != rhsEnabled {
                    return lhsEnabled
                }

                if !filter.isEmpty {
                    let filter = filter.lowercased()

                    let lhsExactCode = lhsToken.coin.code.lowercased() == filter
                    let rhsExactCode = rhsToken.coin.code.lowercased() == filter

                    if lhsExactCode != rhsExactCode {
                        return lhsExactCode
                    }

                    let lhsStartsWithCode = lhsToken.coin.code.lowercased().starts(with: filter)
                    let rhsStartsWithCode = rhsToken.coin.code.lowercased().starts(with: filter)

                    if lhsStartsWithCode != rhsStartsWithCode {
                        return lhsStartsWithCode
                    }

                    let lhsStartsWithName = lhsToken.coin.name.lowercased().starts(with: filter)
                    let rhsStartsWithName = rhsToken.coin.name.lowercased().starts(with: filter)

                    if lhsStartsWithName != rhsStartsWithName {
                        return lhsStartsWithName
                    }
                }
                if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                    return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                }
                return lhsToken.badge ?? "" < rhsToken.badge ?? ""
            }

            let currency = currencyManager.baseCurrency
            let coinPriceMap = marketKit.coinPriceMap(coinUids: wallets.map(\.coin.uid).removeDuplicates(), currencyCode: currency.code)

            let items = sortedResult.map { token in
                var balance: String?
                var fiatBalance: String?

                if let wallet = wallets.first(where: { $0.token == token }),
                   let availableBalance = adapterManager.balanceAdapter(for: wallet)?.balanceData.available
                {
                    balance = ValueFormatter.instance.formatShort(coinValue: CoinValue(kind: .token(token: token), value: availableBalance))

                    if let coinPrice = coinPriceMap[token.coin.uid] {
                        fiatBalance = ValueFormatter.instance.formatShort(currency: currency, value: availableBalance * coinPrice.value)
                    }
                }

                return Item(
                    token: token,
                    balance: balance,
                    fiatBalance: fiatBalance
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
