import RxSwift
import RxRelay

class AddressResolutionService {
    private let provider = AddressResolutionProvider()
    private let coinCode: String
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

    init(coinCode: String, isResolutionEnabled: Bool = true) {
        self.coinCode = coinCode
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

        guard let text = text, provider.isValid(domain: text) else {
            isResolving = false
            return
        }

        isResolving = true

        provider.resolveSingle(domain: text, ticker: coinCode)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] resolvedAddress in
                    self?.isResolving = false
                    self?.resolvedFinishedRelay.accept(Address(raw: resolvedAddress, domain: text))
                }, onError: { [weak self] error in
                    self?.isResolving = false
                    self?.resolvedFinishedRelay.accept(nil)
                })
                .disposed(by: disposeBag)
    }

}
