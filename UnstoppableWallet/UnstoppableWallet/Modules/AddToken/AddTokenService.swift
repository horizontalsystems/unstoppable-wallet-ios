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

    private func joinedCustomTokensSingle(services: [IAddTokenBlockchainService], reference: String) -> Single<[CustomToken]> {
        let singles: [Single<CustomToken?>] = services.map { service in
            service.customTokenSingle(reference: reference)
                    .map { customToken -> CustomToken? in customToken}
                    .catchErrorJustReturn(nil)
        }

        return Single.zip(singles) { customTokens in
            customTokens.compactMap { $0 }
        }
    }

    private func adjusted(customTokens: [CustomToken]) -> [CustomToken] {
        var customTokens = customTokens
        let firstToken = customTokens.removeFirst()

        var result: [CustomToken] = [firstToken]

        for token in customTokens {
            let adjustedCustomToken = CustomToken(
                    coinName: firstToken.coinName,
                    coinCode: firstToken.coinCode,
                    coinType: token.coinType,
                    decimals: firstToken.decimals
            )
            result.append(adjustedCustomToken)
        }

        return result
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

        joinedCustomTokensSingle(services: validServices, reference: reference)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] customTokens in
                    if customTokens.isEmpty {
                        self?.state = .failed(error: TokenError.notFound)
                    } else {
                        self?.state = .fetched(customTokens: customTokens)
                    }
                })
                .disposed(by: disposeBag)
    }

    func save() {
        guard case .fetched(let customTokens) = state else {
            return
        }

        let adjustedCustomTokens = adjusted(customTokens: customTokens)

        coinManager.save(customTokens: adjustedCustomTokens)

        let wallets = adjustedCustomTokens.map { Wallet(platformCoin: $0.platformCoin, account: account) }
        walletManager.save(wallets: wallets)
    }

}

extension AddTokenService {

    enum State {
        case idle
        case loading
        case alreadyExists(platformCoins: [PlatformCoin])
        case fetched(customTokens: [CustomToken])
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
