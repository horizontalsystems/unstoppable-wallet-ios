import RxSwift
import RxRelay
import HsToolKit
import MarketKit

protocol IAddTokenBlockchainService {
    func isValid(reference: String) -> Bool
    func coinType(reference: String) -> CoinType
    func customCoinSingle(reference: String) -> Single<AddTokenModule.CustomCoin>
}

class AddTokenService {
    private let account: Account
    private let blockchainServices: [IAddTokenBlockchainService]
    private let coinManager: CoinManager
    private let walletManager: WalletManager

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(account: Account, blockchainServices: [IAddTokenBlockchainService], coinManager: CoinManager, walletManager: WalletManager) {
        self.account = account
        self.blockchainServices = blockchainServices
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

        var existingPlatformCoins = [PlatformCoin]()

        for service in validServices {
            let coinType = service.coinType(reference: reference)

            if let existingPlatformCoin = try? coinManager.platformCoin(coinType: coinType) {
                existingPlatformCoins.append(existingPlatformCoin)
            }
        }

        if !existingPlatformCoins.isEmpty {
            state = .alreadyExists(platformCoins: existingPlatformCoins)
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

    func save() {
        guard case .fetched(let customCoins) = state else {
            return
        }

        let platformCoins = customCoins.map { customCoin -> PlatformCoin in
            let coinType = customCoin.type
            let coinUid = coinType.customCoinUid

            return PlatformCoin(
                    coin: Coin(uid: coinUid, name: customCoin.name, code: customCoin.code),
                    platform: Platform(coinType: coinType, decimals: customCoin.decimals, coinUid: coinUid)
            )
        }

        let wallets = platformCoins.map { Wallet(platformCoin: $0, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(platformCoins: [PlatformCoin])
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
