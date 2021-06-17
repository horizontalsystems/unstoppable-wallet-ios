import RxSwift
import RxRelay
import HsToolKit
import CoinKit

protocol IAddTokenBlockchainService {
    func isValid(reference: String) -> Bool
    func coinType(reference: String) -> CoinType
    func coinSingle(reference: String) -> Single<Coin>
}

class AddTokenService {
    private let account: Account
    private let blockchainServices: [IAddTokenBlockchainService]
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(account: Account, blockchainServices: [IAddTokenBlockchainService], coinManager: ICoinManager, walletManager: IWalletManager) {
        self.account = account
        self.blockchainServices = blockchainServices
        self.coinManager = coinManager
        self.walletManager = walletManager
    }

    private func chainedCoinSingle(services: [IAddTokenBlockchainService], reference: String) -> Single<Coin> {
        let single = services[0].coinSingle(reference: reference)

        if services.count == 1 {
            return single
        } else {
            let nextSingle = chainedCoinSingle(services: Array(services.dropFirst()), reference: reference)
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

            if let existingCoin = coinManager.coin(type: coinType) {
                state = .alreadyExists(coin: existingCoin)
                return
            }
        }

        state = .loading

        chainedCoinSingle(services: validServices, reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] coin in
                    self?.state = .fetched(coin: coin)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: disposeBag)
    }

    func save() {
        guard case .fetched(let coin) = state else {
            return
        }

        coinManager.save(coins: [coin])

        let wallet = Wallet(coin: coin, account: account)
        walletManager.save(wallets: [wallet])
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(coin: Coin)
        case fetched(coin: Coin)
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
