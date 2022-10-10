import Foundation
import RxSwift
import RxRelay
import HsToolKit
import MarketKit

protocol IAddTokenBlockchainService {
    func isValid(reference: String) -> Bool
    func tokenQuery(reference: String) -> TokenQuery
    func tokenSingle(reference: String) -> Single<Token>
}

class AddTokenService {
    private let account: Account
    private let blockchainServices: [IAddTokenBlockchainService]
    private let marketKit: MarketKit.Kit
    private let coinManager: CoinManager
    private let walletManager: WalletManager

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(account: Account, blockchainServices: [IAddTokenBlockchainService], marketKit: MarketKit.Kit, coinManager: CoinManager, walletManager: WalletManager) {
        self.account = account
        self.blockchainServices = blockchainServices
        self.marketKit = marketKit
        self.coinManager = coinManager
        self.walletManager = walletManager
    }

    private func joinedTokensSingle(services: [IAddTokenBlockchainService], reference: String) -> Single<[Token]> {
        let singles: [Single<Token?>] = services.map { service in
            service.tokenSingle(reference: reference)
                    .map { token -> Token? in token}
                    .catchErrorJustReturn(nil)
        }

        return Single.zip(singles) { tokens in
            tokens.compactMap { $0 }
        }
    }

    private func initialItems(tokens: [Token]) -> ([Item], [Item]) {
        let activeTokens = walletManager.activeWallets.map { $0.token }

        let sortedTokens = tokens.sorted { lhsToken, rhsToken in
            lhsToken.blockchain.type.order < rhsToken.blockchain.type.order
        }

        let addedTokens = sortedTokens.filter { activeTokens.contains($0) }
        let tokens = sortedTokens.filter { !activeTokens.contains($0) }

        let addedItems = addedTokens.map { Item(token: $0, enabled: true) }
        let items = tokens.map { Item(token: $0, enabled: true) }

        return (addedItems, items)
    }

    private func handleInitialState(tokens: [Token]) {
        if tokens.isEmpty {
            state = .failed(error: TokenError.notFound)
        } else {
            let (addedItems, items) = initialItems(tokens: tokens)
            state = .fetched(addedItems: addedItems, items: items)
        }
    }

}

extension AddTokenService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(reference: String?) {
        disposeBag = DisposeBag()

        guard let reference = reference, !reference.isEmpty else {
            state = .idle
            return
        }

        let validServices = blockchainServices.filter { $0.isValid(reference: reference) }

        guard !validServices.isEmpty else {
            state = .failed(error: TokenError.invalidReference)
            return
        }

        var tokens = [Token]()
        var notFoundServices = [IAddTokenBlockchainService]()

        for service in validServices {
            let tokenQuery = service.tokenQuery(reference: reference)

            if let existingToken = try? coinManager.token(query: tokenQuery) {
                tokens.append(existingToken)
            } else {
                notFoundServices.append(service)
            }
        }

        if notFoundServices.isEmpty {
            handleInitialState(tokens: tokens)
            return
        }

        state = .loading

        joinedTokensSingle(services: notFoundServices, reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] serviceTokens in
                    self?.handleInitialState(tokens: tokens + serviceTokens)
                })
                .disposed(by: disposeBag)
    }

    func toggleToken(index: Int) {
        guard case .fetched(let addedItems, let items) = state else {
            return
        }

        guard index < items.count else {
            return
        }

        items[index].enabled = !items[index].enabled

        state = .fetched(addedItems: addedItems, items: items)
    }

    func save() throws {
        guard case .fetched(_, let items) = state else {
            return
        }

        let enabledItems = items.filter { $0.enabled }

        guard !enabledItems.isEmpty else {
            return
        }

        let wallets = enabledItems.map { Wallet(token: $0.token, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case fetched(addedItems: [Item], items: [Item])
        case failed(error: Error)
    }

    class Item {
        let token: Token
        var enabled: Bool

        init(token: Token, enabled: Bool) {
            self.token = token
            self.enabled = enabled
        }
    }

    enum TokenError: LocalizedError {
        case invalidReference
        case notFound

        var errorDescription: String? {
            switch self {
            case .invalidReference: return "add_token.invalid_contract_address_or_bep2_symbol".localized
            case .notFound: return "add_token.token_not_found".localized
            }
        }
    }

}
