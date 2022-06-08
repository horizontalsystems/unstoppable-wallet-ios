import RxSwift
import RxRelay
import HsToolKit
import MarketKit

protocol IAddTokenBlockchainService {
    func isValid(reference: String) -> Bool
    func tokenQuery(reference: String) -> TokenQuery
    func customCoinSingle(reference: String) -> Single<AddTokenModule.CustomCoin>
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

    private func joinedCustomCoinsSingle(services: [IAddTokenBlockchainService], reference: String) -> Single<[AddTokenModule.CustomCoin]> {
        let singles: [Single<AddTokenModule.CustomCoin?>] = services.map { service in
            service.customCoinSingle(reference: reference)
                    .map { customCoin -> AddTokenModule.CustomCoin? in customCoin}
                    .catchErrorJustReturn(nil)
        }

        return Single.zip(singles) { customCoins in
            customCoins.compactMap { $0 }
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

        var existingTokens = [Token]()

        for service in validServices {
            let tokenQuery = service.tokenQuery(reference: reference)

            if let existingToken = try? coinManager.token(query: tokenQuery) {
                existingTokens.append(existingToken)
            }
        }

        if !existingTokens.isEmpty {
            state = .alreadyExists(tokens: existingTokens)
            return
        }

        state = .loading

        joinedCustomCoinsSingle(services: validServices, reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] customCoins in
                    if customCoins.isEmpty {
                        self?.state = .failed(error: TokenError.notFound)
                    } else {
                        self?.state = .fetched(customCoins: customCoins)
                    }
                })
                .disposed(by: disposeBag)
    }

    func save() throws {
        guard case .fetched(let customCoins) = state else {
            return
        }

        let blockchains = try marketKit.blockchains(uids: customCoins.map { $0.tokenQuery.blockchainType.uid })

        let tokens = customCoins.compactMap { customCoin -> Token? in
            guard let blockchain = blockchains.first(where: { $0.uid == customCoin.tokenQuery.blockchainType.uid }) else {
                return nil
            }

            let coinUid = customCoin.tokenQuery.customCoinUid

            return Token(
                    coin: Coin(uid: coinUid, name: customCoin.name, code: customCoin.code),
                    blockchain: blockchain,
                    type: customCoin.tokenQuery.tokenType,
                    decimals: customCoin.decimals
            )
        }

        let wallets = tokens.map { Wallet(token: $0, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(tokens: [Token])
        case fetched(customCoins: [AddTokenModule.CustomCoin])
        case failed(error: Error)
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
