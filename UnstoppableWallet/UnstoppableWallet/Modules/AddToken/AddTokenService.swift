import Foundation
import RxSwift
import RxRelay
import HsToolKit
import MarketKit

protocol IAddTokenBlockchainService {
    var placeholder: String { get }
    func validate(reference: String) throws
    func tokenQuery(reference: String) -> TokenQuery
    func tokenSingle(reference: String) -> Single<Token>
}

class AddTokenService {
    private let account: Account
    private let items: [AddTokenModule.Item]
    private let coinManager: CoinManager
    private let walletManager: WalletManager

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let currentBlockchainItemRelay = PublishRelay<CurrentBlockchainItem>()
    private(set) var currentBlockchainItem: CurrentBlockchainItem {
        didSet {
            currentBlockchainItemRelay.accept(currentBlockchainItem)
        }
    }

    private var currentIndex: Int = 0
    private var currentReference: String?

    init(account: Account, items: [AddTokenModule.Item], coinManager: CoinManager, walletManager: WalletManager) {
        let sortedItems = items.sorted(by: { $0.blockchain.type.order < $1.blockchain.type.order })

        self.account = account
        self.items = sortedItems
        self.coinManager = coinManager
        self.walletManager = walletManager

        currentBlockchainItem = CurrentBlockchainItem(item: sortedItems[0])
    }

    private func syncState() {
        disposeBag = DisposeBag()

        guard let reference = currentReference, !reference.isEmpty else {
            state = .idle
            return
        }

        let service = items[currentIndex].service

        do {
            try service.validate(reference: reference)
        } catch {
            state = .failed(error: error)
            return
        }

        let tokenQuery = service.tokenQuery(reference: reference)

        if let existingToken = try? coinManager.token(query: tokenQuery) {
            state = .alreadyExists(token: existingToken)
            return
        }

        state = .loading

        service.tokenSingle(reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(
                        onSuccess: { [weak self] token in
                            self?.state = .fetched(token: token)
                        },
                        onError: { [weak self] error in
                            self?.state = .failed(error: error)
                        }
                )
                .disposed(by: disposeBag)
    }

}

extension AddTokenService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var currentBlockchainItemObservable: Observable<CurrentBlockchainItem> {
        currentBlockchainItemRelay.asObservable()
    }

    var blockchainItems: [BlockchainItem] {
        items.enumerated().map { index, item in
            BlockchainItem(blockchain: item.blockchain, current: index == currentIndex)
        }
    }

    func setBlockchain(index: Int) {
        currentIndex = index
        currentBlockchainItem = CurrentBlockchainItem(item: items[index])
        syncState()
    }

    func set(reference: String?) {
        currentReference = reference
        syncState()
    }

    func save() {
        guard case .fetched(let token) = state else {
            return
        }

        let wallet = Wallet(token: token, account: account)
        walletManager.save(wallets: [wallet])
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(token: Token)
        case fetched(token: Token)
        case failed(error: Error)
    }

    struct BlockchainItem {
        let blockchain: Blockchain
        let current: Bool
    }

    struct CurrentBlockchainItem {
        let blockchain: Blockchain
        let placeholder: String

        init(item: AddTokenModule.Item) {
            blockchain = item.blockchain
            placeholder = item.service.placeholder
        }
    }

}
