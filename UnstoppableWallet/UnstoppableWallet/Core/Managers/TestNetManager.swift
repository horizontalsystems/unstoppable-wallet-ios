import Foundation
import MarketKit
import RxRelay
import RxSwift
import StorageKit

class TestNetManager {
    static let instance = TestNetManager()

    let localStorage: LocalStorage
    private let disposeBag = DisposeBag()

    private let testNetModeUpdatedRelay = PublishRelay<Bool>()

    init() {
        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default) // avoid create instance through App.shared
    }

    private var blockchainTypes: [BlockchainType] {
        [.ethereumGoerli]
    }

    var blockchains: [Blockchain] {
        guard localStorage.testNetMode else {
            return []
        }
        return blockchainTypes.compactMap { blockchain(blockchainType: $0) }
    }

    func nativeTokens(filter: String? = nil) -> [Token] {
        guard localStorage.testNetMode else {
            return []
        }
        let tokens = blockchainTypes.compactMap { nativeToken(blockchainType: $0) }
        if let filter = filter?.lowercased() {
            return tokens.filter { token in
                token.coin.name.lowercased().contains(filter) || token.coin.code.lowercased().contains(filter)
            }
        }
        return tokens
    }

    func blockchain(blockchainType: BlockchainType) -> Blockchain? {
        switch blockchainType {
        case .ethereumGoerli: return Blockchain(type: .ethereumGoerli, name: "Ethereum Goerli", explorerUrl: nil)
        default: return nil
        }
    }

    func nativeToken(blockchainType: BlockchainType) -> Token? {
        guard let blockchain = blockchain(blockchainType: blockchainType) else {
            return nil
        }

        switch blockchainType {
        case .ethereumGoerli:
            return Token(
                    coin: Coin(uid: "ethereum", name: "Ethereum", code: "ETH"),
                    blockchain: blockchain,
                    type: .native,
                    decimals: 18
            )
        default: return nil
        }
    }

    // Analog MarketKit methods for Tokens and blockchains

    // get testNet hardcoded tokens
    func tokens(queries: [TokenQuery]) throws -> [Token] {
        queries.compactMap { query in
            // For now can return only native tokens
            guard query.tokenType == .native else {
                return nil
            }

            return nativeToken(blockchainType: query.blockchainType)
        }
    }

}

extension TestNetManager {

    var testNetMode: Bool {
        get { localStorage.testNetMode }
        set {
            guard localStorage.testNetMode != newValue else {
                return
            }
            localStorage.testNetMode = newValue
            testNetModeUpdatedRelay.accept(newValue)
        }
    }
    
    var testNetModeUpdatedObservable: Observable<Bool> {
        testNetModeUpdatedRelay.asObservable()
    }

}

extension BlockchainType {

    var isTestNet: Bool {
        switch self {
        case .ethereumGoerli: return true
        default: return false
        }
    }

}
