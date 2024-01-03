import Combine
import EvmKit
import HsExtensions
import MarketKit

class MultiSwapTokenSelectViewModel: ObservableObject {
    private var syncTask: AnyTask?

    private let marketKit = App.shared.marketKit
    private let accountManager = App.shared.accountManager
    private let wallets = App.shared.walletManager.activeWallets

    @Published var searchText: String = "" {
        didSet {
            syncTokens()
        }
    }

    @Published var tokens: [Token] = []

    init() {
        syncTokens()
    }

    private func syncTokens() {
        syncTask = nil

        let filter = searchText.trimmingCharacters(in: .whitespaces)

        guard let account = accountManager.activeAccount else {
            tokens = []
            return
        }

        syncTask = Task { [weak self, marketKit, wallets] in
            let result: [Token]

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

                    result = (enabledTokens + featuredTokens).removeDuplicates()
                } else if let ethAddress = try? EvmKit.Address(hex: filter) {
                    let address = ethAddress.hex
                    let tokens = try marketKit.tokens(reference: address)

                    result = tokens.filter { account.type.supports(token: $0) }
                } else {
                    let allFullCoins = try marketKit.fullCoins(filter: filter, limit: 100)
                    let tokens = allFullCoins.map(\.tokens).flatMap { $0 }

                    result = tokens.filter { account.type.supports(token: $0) }
                }
            } catch {
                result = []
            }

            let sortedResult = result.sorted { lhsToken, rhsToken in
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

            if !Task.isCancelled {
                await MainActor.run { [weak self] in
                    self?.tokens = sortedResult
                }
            }
        }
        .erased()
    }
}
