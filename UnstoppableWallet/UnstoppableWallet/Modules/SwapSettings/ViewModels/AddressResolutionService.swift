import RxSwift
import RxRelay
import MarketKit

class AddressResolutionService {
    private let provider = AddressResolutionProvider()
    private let coinCode: String
    private let chain: String?
    private let isResolutionEnabled: Bool
    private var disposeBag = DisposeBag()

    private(set) var isResolving: Bool = false {
        didSet {
            if oldValue != isResolving {
                isResolvingRelay.accept(isResolving)
            }
        }
    }
    private let isResolvingRelay = PublishRelay<Bool>()
    private let resolvedFinishedRelay = PublishRelay<Address?>()

    init(coinCode: String, chain: String?, isResolutionEnabled: Bool = true) {
        self.coinCode = coinCode
        self.chain = chain
        self.isResolutionEnabled = isResolutionEnabled
    }

}

extension AddressResolutionService {

    var resolveFinishedObservable: Observable<Address?> {
        resolvedFinishedRelay.asObservable()
    }

    var isResolvingObservable: Observable<Bool> {
        isResolvingRelay.asObservable()
    }

    func set(text: String?) {
        guard isResolutionEnabled else {
            return
        }

        disposeBag = DisposeBag()

        guard let text = text, text.contains(".") else {
            isResolving = false
            return
        }

        isResolving = true

        provider
                .isValid(domain: text)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] isValid in
                    self?.resolve(valid: isValid, domain: text)
                })
                .disposed(by: disposeBag)
    }

    private func resolve(valid: Bool, domain: String) {
        guard valid else {
            isResolving = false
            return
        }
        provider
                .resolveSingle(domain: domain, ticker: coinCode, chain: chain)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] resolvedAddress in
                    self?.isResolving = false
                    self?.resolvedFinishedRelay.accept(Address(raw: resolvedAddress, domain: domain))
                }, onError: { [weak self] error in
                    self?.isResolving = false
                    self?.resolvedFinishedRelay.accept(nil)
                })
                .disposed(by: disposeBag)
    }

}

extension AddressResolutionService {

    static func chainCoinCode(coinType: CoinType) -> String? {
        switch coinType {
        case .ethereum: return "ETH"
        case .erc20: return "ETH"
        case .bitcoin: return "BTC"
        default: return nil
        }
    }

    static func chain(coinType: CoinType) -> String? {
        switch coinType {
        case .erc20: return "ERC20"
        case .bep20: return "BEP20"
        default: return nil
        }
    }

}