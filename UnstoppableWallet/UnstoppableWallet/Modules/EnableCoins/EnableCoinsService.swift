import RxSwift
import RxRelay
import EthereumKit
import BinanceChainKit
import MarketKit

class EnableCoinsService {
    private let appConfigProvider: AppConfigProvider
    private let erc20Provider: EnableCoinsEip20Provider
    private let bep20Provider: EnableCoinsEip20Provider
    private let bep2Provider: EnableCoinsBep2Provider
    private let disposeBag = DisposeBag()

    private let enableCoinTypesRelay = PublishRelay<[CoinType]>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(appConfigProvider: AppConfigProvider, erc20Provider: EnableCoinsEip20Provider, bep20Provider: EnableCoinsEip20Provider, bep2Provider: EnableCoinsBep2Provider) {
        self.appConfigProvider = appConfigProvider
        self.erc20Provider = erc20Provider
        self.bep20Provider = bep20Provider
        self.bep2Provider = bep2Provider
    }

    private func handle(fetchedCoinTypes coinTypes: [CoinType]) {
        state = .success
        enableCoinTypesRelay.accept(coinTypes)
    }

    private func resolveTokenType(coinType: CoinType, accountType: AccountType) -> TokenType? {
        guard let seed = accountType.mnemonicSeed else {
            return nil
        }

        switch coinType {
        case .ethereum:
            return .erc20(seed: seed)
        case .binanceSmartChain:
            return .bep20(seed: seed)
        case .bep2(let symbol):
            if symbol == "BNB" {
                return .bep2(seed: seed)
            }
        default:
            ()
        }

        return nil
    }

    private func fetchErc20Tokens(seed: Data) {
        do {
            let address = try Kit.address(seed: seed, networkType: appConfigProvider.testMode ? .ropsten : .ethMainNet)

            state = .loading

            erc20Provider.coinTypesSingle(address: address.hex)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] coinTypes in
                        self?.handle(fetchedCoinTypes: coinTypes)
                    }, onError: { [weak self] error in
                        self?.state = .failure(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            state = .failure(error: error)
        }
    }

    private func fetchBep20Tokens(seed: Data) {
        do {
            let address = try Kit.address(seed: seed, networkType: .bscMainNet)

            state = .loading

            bep20Provider.coinTypesSingle(address: address.hex)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] coinTypes in
                        self?.handle(fetchedCoinTypes: coinTypes)
                    }, onError: { [weak self] error in
                        self?.state = .failure(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            state = .failure(error: error)
        }
    }

    private func fetchBep2Tokens(seed: Data) {
        do {
            let single = try bep2Provider.tokenSymbolsSingle(seed: seed)

            state = .loading

            single
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] tokenSymbols in
                        self?.handleFetchBep2(tokenSymbols: tokenSymbols)
                    }, onError: { [weak self] error in
                        self?.state = .failure(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            state = .failure(error: error)
        }
    }

    private func handleFetchBep2(tokenSymbols: [String]) {
        let coinTypes = tokenSymbols.compactMap { tokenSymbol -> CoinType? in
            if tokenSymbol == "BNB" {
                return nil
            }

            return .bep2(symbol: tokenSymbol)
        }

        handle(fetchedCoinTypes: coinTypes)
    }

}

extension EnableCoinsService {

    var enableCoinTypesObservable: Observable<[CoinType]> {
        enableCoinTypesRelay.asObservable()
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func handle(coinTypes: [CoinType], accountType: AccountType) {
        let tokenTypes = coinTypes.compactMap { resolveTokenType(coinType: $0, accountType: accountType) }

        guard let tokenType = tokenTypes.first else {
            return
        }

        state = .waitingForApprove(tokenType: tokenType)
    }

    func approveEnable() {
        guard case .waitingForApprove(let tokenType) = state else {
            return
        }

        switch tokenType {
        case .erc20(let seed):
            fetchErc20Tokens(seed: seed)
        case .bep20(let seed):
            fetchBep20Tokens(seed: seed)
        case .bep2(let seed):
            fetchBep2Tokens(seed: seed)
        }
    }

}

extension EnableCoinsService {

    enum State {
        case idle
        case waitingForApprove(tokenType: TokenType)
        case loading
        case success
        case failure(error: Error)
    }

    enum TokenType {
        case erc20(seed: Data)
        case bep20(seed: Data)
        case bep2(seed: Data)

        var title: String {
            switch self {
            case .erc20: return "ERC20"
            case .bep20: return "BEP20"
            case .bep2: return "BEP2"
            }
        }
    }

}
