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

        guard let account = accountManager.activeAccount else {
            items = []
            return
        }

        syncTask = Task { [weak self, marketKit, walletManager, adapterManager, currencyManager, token] in
            let wallets = walletManager.activeWallets
            var resultTokens = [Token]()

            do {
                if filter.isEmpty {
                    let enabledTokens = wallets
                        .map(\.token)
                        .sorted { lhsToken, rhsToken in
                            if let token {
                                let lhsSameBlockchain = lhsToken.blockchainType == token.blockchainType
                                let rhsSameBlockchain = rhsToken.blockchainType == token.blockchainType

                                if lhsSameBlockchain != rhsSameBlockchain {
                                    return lhsSameBlockchain
                                }
                            }

                            if lhsToken.coin.code != rhsToken.coin.code {
                                return lhsToken.coin.code < rhsToken.coin.code
                            }

                            if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                                return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                            }

                            return lhsToken.badge ?? "" < rhsToken.badge ?? ""
                        }

                    resultTokens.append(contentsOf: enabledTokens)

                    if let token {
                        let topFullCoins = try marketKit.topFullCoins(limit: 100)

                        let tokens = topFullCoins
                            .map { $0.tokens.filter { $0.blockchainType == token.blockchainType } }
                            .flatMap { $0 }

                        let suggestedTokens = tokens
                            .filter { account.type.supports(token: $0) && !resultTokens.contains($0) }
                            .sorted { lhsToken, rhsToken in
                                let lhsRank = lhsToken.coin.marketCapRank ?? Int.max
                                let rhsRank = rhsToken.coin.marketCapRank ?? Int.max

                                if lhsRank != rhsRank {
                                    return lhsRank < rhsRank
                                }

                                if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                                    return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                                }

                                return lhsToken.badge ?? "" < rhsToken.badge ?? ""
                            }

                        resultTokens.append(contentsOf: suggestedTokens)
                    }

                    let tokenQueries: [TokenQuery]
                    if case .hdExtendedKey = account.type {
                        tokenQueries = BtcBlockchainManager.blockchainTypes.map(\.nativeTokenQueries).flatMap { $0 }
                    } else {
                        tokenQueries = BlockchainType.supported.map(\.defaultTokenQuery)
                    }

                    let tokens = try marketKit.tokens(queries: tokenQueries)

                    let featuredTokens = tokens
                        .filter { account.type.supports(token: $0) && !resultTokens.contains($0) }
                        .sorted { lhsToken, rhsToken in
                            if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                                return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                            }

                            return lhsToken.badge ?? "" < rhsToken.badge ?? ""
                        }

                    resultTokens.append(contentsOf: featuredTokens)
                } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                    let address = ethAddress.hex
                    let tokens = try marketKit.tokens(reference: address)

                    resultTokens = tokens
                        .filter { account.type.supports(token: $0) }
                        .sorted { lhsToken, rhsToken in
                            let lhsEnabled = wallets.contains { $0.token == lhsToken }
                            let rhsEnabled = wallets.contains { $0.token == rhsToken }

                            if lhsEnabled != rhsEnabled {
                                return lhsEnabled
                            }

                            if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                                return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                            }

                            return lhsToken.badge ?? "" < rhsToken.badge ?? ""
                        }
                } else {
                    let allFullCoins = try marketKit.fullCoins(filter: filter, limit: 100)
                    let tokens = allFullCoins.map(\.tokens).flatMap { $0 }

                    resultTokens = tokens
                        .filter { account.type.supports(token: $0) }
                        .sorted { lhsToken, rhsToken in
                            let lhsEnabled = wallets.contains { $0.token == lhsToken }
                            let rhsEnabled = wallets.contains { $0.token == rhsToken }

                            if lhsEnabled != rhsEnabled {
                                return lhsEnabled
                            }

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

                            if lhsToken.blockchainType.order != rhsToken.blockchainType.order {
                                return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                            }

                            return lhsToken.badge ?? "" < rhsToken.badge ?? ""
                        }
                }
            } catch {}

            let currency = currencyManager.baseCurrency
            let coinPriceMap = marketKit.coinPriceMap(coinUids: wallets.map(\.coin.uid).removeDuplicates(), currencyCode: currency.code)

            let items = resultTokens.map { token in
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
