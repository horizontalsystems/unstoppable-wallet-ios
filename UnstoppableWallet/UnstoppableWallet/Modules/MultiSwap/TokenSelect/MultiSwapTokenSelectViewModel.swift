import Combine
import EvmKit
import Foundation
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

                            let lhsFiatBalance = fiatBalances[lhsToken] ?? 0
                            let rhsFiatBalance = fiatBalances[rhsToken] ?? 0

                            if lhsFiatBalance != rhsFiatBalance {
                                return lhsFiatBalance > rhsFiatBalance
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
                            let lhsEnabled = balances[lhsToken] != nil
                            let rhsEnabled = balances[rhsToken] != nil

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
                            let lhsEnabled = balances[lhsToken] != nil
                            let rhsEnabled = balances[rhsToken] != nil

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

            let items = resultTokens.map { token in
                var balanceString: String?
                var fiatBalanceString: String?

                if let balance = balances[token] {
                    balanceString = ValueFormatter.instance.formatShort(coinValue: CoinValue(kind: .token(token: token), value: balance))

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
