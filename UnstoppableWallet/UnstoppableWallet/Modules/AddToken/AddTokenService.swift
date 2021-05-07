import RxSwift
import RxRelay
import HsToolKit
import CoinKit

protocol IAddTokenBlockchainService {
    func validate(reference: String) throws
    func coinType(reference: String) -> CoinType
    func coinSingle(reference: String) -> Single<Coin>
}

class AddTokenService {
    private let blockchainService: IAddTokenBlockchainService
    private let coinManager: ICoinManager
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(blockchainService: IAddTokenBlockchainService, coinManager: ICoinManager, walletManager: IWalletManager, accountManager: IAccountManager) {
        self.blockchainService = blockchainService
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.accountManager = accountManager
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

        do {
            try blockchainService.validate(reference: reference)
        } catch {
            state = .failed(error: error)
            return
        }

        if let existingCoin = coinManager.coin(type: blockchainService.coinType(reference: reference)) {
            state = .alreadyExists(coin: existingCoin)
            return
        }

        state = .loading

        blockchainService.coinSingle(reference: reference)
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

        guard let account = accountManager.activeAccount else {
            return
        }

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

}
