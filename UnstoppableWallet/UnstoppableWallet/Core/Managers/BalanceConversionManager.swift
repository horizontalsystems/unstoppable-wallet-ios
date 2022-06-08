import RxSwift
import RxRelay
import StorageKit
import MarketKit

class BalanceConversionManager {
    private let blockchainTypes: [BlockchainType] = [.bitcoin, .ethereum, .binanceSmartChain]
    private let keyBlockchainUid = "conversion-blockchain-uid"

    private let marketKit: MarketKit.Kit
    private let localStorage: StorageKit.ILocalStorage

    let conversionTokens: [Token]

    private let conversionTokenRelay = PublishRelay<Token?>()
    private(set) var conversionToken: Token? {
        didSet {
            conversionTokenRelay.accept(conversionToken)
            localStorage.set(value: conversionToken?.blockchain.uid, for: keyBlockchainUid)
        }
    }

    init(marketKit: MarketKit.Kit, localStorage: StorageKit.ILocalStorage) {
        self.localStorage = localStorage
        self.marketKit = marketKit

        do {
            let queries = blockchainTypes.map { TokenQuery(blockchainType: $0, tokenType: .native) }
            let tokens = try marketKit.tokens(queries: queries)
            conversionTokens = blockchainTypes.compactMap { blockchainType in
                tokens.first { $0.blockchainType == blockchainType }
            }
        } catch {
            conversionTokens = []
        }

        let blockchainUid: String? = localStorage.value(for: keyBlockchainUid)
        let blockchainType = blockchainUid.map { BlockchainType(uid: $0) }

        if let blockchainType = blockchainType, let token = conversionTokens.first(where: { $0.blockchainType == blockchainType }) {
            conversionToken = token
        } else {
            conversionToken = conversionTokens.first
        }
    }

}

extension BalanceConversionManager {

    var conversionTokenObservable: Observable<Token?> {
        conversionTokenRelay.asObservable()
    }

    func toggleConversionToken() {
        guard conversionTokens.count > 1, let conversionToken = conversionToken else {
            return
        }

        let currentIndex = conversionTokens.firstIndex(of: conversionToken) ?? 0
        let newIndex = (currentIndex + 1) % conversionTokens.count
        self.conversionToken = conversionTokens[newIndex]
    }

    func setConversionToken(index: Int) {
        guard index < conversionTokens.count else {
            return
        }

        conversionToken = conversionTokens[index]
    }

}
