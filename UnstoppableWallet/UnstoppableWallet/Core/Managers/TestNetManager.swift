import Foundation
import MarketKit
import RxRelay
import RxSwift
import StorageKit

class TestNetManager {
    private let keyTestNetEnabled = "test-net-enabled"

    private let localStorage: ILocalStorage
    private let disposeBag = DisposeBag()

    private let testNetEnabledRelay = PublishRelay<Bool>()

    var testNetEnabled: Bool {
        didSet {
            guard oldValue != testNetEnabled else {
                return
            }

            localStorage.set(value: testNetEnabled, for: keyTestNetEnabled)
            testNetEnabledRelay.accept(testNetEnabled)
        }
    }

    init(localStorage: ILocalStorage) {
        self.localStorage = localStorage

        testNetEnabled = localStorage.value(for: keyTestNetEnabled) ?? false
    }

    private var blockchainTypes: [BlockchainType] {
        [.ethereumGoerli]
    }

    var blockchains: [Blockchain] {
        blockchainTypes.compactMap {
            blockchain(blockchainType: $0)
        }
    }

    var baseTokens: [Token] {
        blockchainTypes.compactMap { baseToken(blockchainType: $0) }
    }

    func baseTokens(filter: String) -> [Token] {
        baseTokens.filter { token in
            token.coin.name.lowercased().contains(filter.lowercased()) || token.coin.code.lowercased().contains(filter.lowercased())
        }
    }

    func blockchain(blockchainType: BlockchainType) -> Blockchain? {
        switch blockchainType {
        case .ethereumGoerli: return Blockchain(type: .ethereumGoerli, name: "Ethereum Goerli", explorerUrl: nil)
        default: return nil
        }
    }

    func baseToken(blockchainType: BlockchainType) -> Token? {
        guard let blockchain = blockchain(blockchainType: blockchainType) else {
            return nil
        }

        switch blockchainType {
        case .ethereumGoerli:
            return Token(
                    coin: Coin(uid: "ethereum-goerli", name: "Ethereum Goerli", code: "gETH"),
                    blockchain: blockchain,
                    type: .native,
                    decimals: 18
            )
        default: return nil
        }
    }

}

extension TestNetManager {

    var testNetEnabledObservable: Observable<Bool> {
        testNetEnabledRelay.asObservable()
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
