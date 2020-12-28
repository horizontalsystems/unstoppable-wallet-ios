import RxSwift
import RxRelay

class AddressResolutionService {
    private let provider = AddressResolutionProvider()
    private let coinCode: String
    private var disposeBag = DisposeBag()

    private(set) var isResolving: Bool = false {
        didSet {
            isResolvingRelay.accept(isResolving)
        }
    }
    private let isResolvingRelay = PublishRelay<Bool>()

    private let addressRelay = PublishRelay<Address?>()

    init(coinCode: String) {
        self.coinCode = coinCode
    }

}

extension AddressResolutionService {

    var addressObservable: Observable<Address?> {
        addressRelay.asObservable()
    }

    var isResolvingObservable: Observable<Bool> {
        isResolvingRelay.asObservable()
    }

    func set(text: String?) {
        disposeBag = DisposeBag()

        addressRelay.accept(text.map { Address(raw: $0) })

        if let text = text, provider.isValid(domain: text) {
            isResolving = true

            provider.resolveSingle(domain: text, ticker: coinCode)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] address in
                        self?.addressRelay.accept(Address(raw: address, domain: text))
                        self?.isResolving = false
                    }, onError: { [weak self] error in
                        self?.isResolving = false
                    })
                    .disposed(by: disposeBag)
        } else {
            isResolving = false
        }
    }

}
