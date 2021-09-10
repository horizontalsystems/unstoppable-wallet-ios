import RxSwift
import RxRelay
import HsToolKit
import MarketKit

protocol IAddTokenBlockchainService {
    func isValid(reference: String) -> Bool
    func coinType(reference: String) -> CoinType
    func customTokenSingle(reference: String) -> Single<CustomToken>
}

class AddTokenService {
    private let account: Account
    private let blockchainServices: [IAddTokenBlockchainService]
    private let coinManager: CoinManagerNew
    private let walletManager: WalletManagerNew

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(account: Account, blockchainServices: [IAddTokenBlockchainService], coinManager: CoinManagerNew, walletManager: WalletManagerNew) {
        self.account = account
        self.blockchainServices = blockchainServices
        self.coinManager = coinManager
        self.walletManager = walletManager
    }

    private func chainedCustomTokenSingle(services: [IAddTokenBlockchainService], reference: String) -> Single<CustomToken> {
        let single = services[0].customTokenSingle(reference: reference)

        if services.count == 1 {
            return single
        } else {
            let nextSingle = chainedCustomTokenSingle(services: Array(services.dropFirst()), reference: reference)
            return single.catchError { _ in nextSingle }
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
            state = .failed(error: ValidationError.invalidReference)
            return
        }

        for service in validServices {
            let coinType = service.coinType(reference: reference)

            if let existingPlatformCoin = try? coinManager.platformCoin(coinType: coinType) {
                state = .alreadyExists(platformCoin: existingPlatformCoin)
                return
            }
        }

        state = .loading

        chainedCustomTokenSingle(services: validServices, reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] customToken in
                    self?.state = .fetched(customToken: customToken)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

    func save() {
        guard case .fetched(let customToken) = state else {
            return
        }

        coinManager.save(customTokens: [customToken])

        let wallet = WalletNew(platformCoin: customToken.platformCoin, account: account)
        walletManager.save(wallets: [wallet])
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(platformCoin: PlatformCoin)
        case fetched(customToken: CustomToken)
        case failed(error: Error)
    }

    enum ValidationError: LocalizedError {
        case invalidReference

        var errorDescription: String? {
            switch self {
            case .invalidReference: return "add_token.invalid_contract_address_or_bep2_symbol".localized
            }
        }
    }

}
