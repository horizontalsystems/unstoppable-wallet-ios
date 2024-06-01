import HsExtensions
import MarketKit

class BalanceConversionManager {
    private let tokenQueries = [
        TokenQuery(blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84)),
        TokenQuery(blockchainType: .ethereum, tokenType: .native),
    ]
    private let keyBlockchainUid = "conversion-blockchain-uid"

    private let marketKit: MarketKit.Kit
    private let userDefaultsStorage: UserDefaultsStorage

    let conversionTokens: [Token]

    @PostPublished private(set) var conversionToken: Token? {
        didSet {
            userDefaultsStorage.set(value: conversionToken?.blockchain.uid, for: keyBlockchainUid)
        }
    }

    init(marketKit: MarketKit.Kit, userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage
        self.marketKit = marketKit

        do {
            let tokens = try marketKit.tokens(queries: tokenQueries)
            conversionTokens = tokenQueries.compactMap { tokenQuery in
                tokens.first { $0.tokenQuery == tokenQuery }
            }
        } catch {
            conversionTokens = []
        }

        let blockchainUid: String? = userDefaultsStorage.value(for: keyBlockchainUid)
        let blockchainType = blockchainUid.map { BlockchainType(uid: $0) }

        if let blockchainType, let token = conversionTokens.first(where: { $0.blockchainType == blockchainType }) {
            conversionToken = token
        } else {
            conversionToken = conversionTokens.first
        }
    }
}

extension BalanceConversionManager {
    func toggleConversionToken() {
        guard conversionTokens.count > 1, let conversionToken else {
            return
        }

        let currentIndex = conversionTokens.firstIndex(of: conversionToken) ?? 0
        let newIndex = (currentIndex + 1) % conversionTokens.count
        self.conversionToken = conversionTokens[newIndex]
    }

    func set(conversionToken: Token?) {
        guard self.conversionToken != conversionToken else {
            return
        }

        self.conversionToken = conversionToken
    }

    func set(tokenQueryId: String?) {
        conversionToken = tokenQueryId
            .flatMap { TokenQuery(id: $0) }
            .flatMap { tokenQueries.contains($0) ? $0 : nil }
            .flatMap { try? marketKit.token(query: $0) } ??
            conversionTokens.first
    }
}
