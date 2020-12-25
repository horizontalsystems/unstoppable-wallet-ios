import RxSwift
import RxRelay

class AddressResolutionService {
    private let provider = AddressResolutionProvider()
    private var disposeBag = DisposeBag()

    private(set) var isResolving: Bool = false {
        didSet {
            isResolvingRelay.accept(isResolving)
        }
    }
    private let isResolvingRelay = PublishRelay<Bool>()

    private let addressRelay = PublishRelay<String?>()

    init() {
    }

}

extension AddressResolutionService {

    var addressObservable: Observable<String?> {
        addressRelay.asObservable()
    }

    var isResolvingObservable: Observable<Bool> {
        isResolvingRelay.asObservable()
    }

    func set(text: String?) {
        disposeBag = DisposeBag()

        addressRelay.accept(text)

        if let text = text, provider.isValid(domain: text) {
            isResolving = true

            provider.resolutionSingle(domain: text)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .subscribe(onSuccess: { [weak self] address in
                        self?.addressRelay.accept(address)
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

class AddressResolutionProvider {

    func isValid(domain: String) -> Bool {
        domain.hasSuffix("zil") || domain.hasSuffix("crypto")
    }

    func resolutionSingle(domain: String) -> Single<String> {
        Single<String>.create { observer in
            Thread.sleep(forTimeInterval: 2)

            if domain.hasSuffix("zil") {
                observer(.success("0xe94B8B542f474e3Dd52Ff92c6c60c0908a9F1235"))
            } else {
                observer(.error(ResolutionError.invalidDomain))
            }

            return Disposables.create()
        }
    }

}

extension AddressResolutionProvider {

    enum ResolutionError: Error {
        case invalidDomain
    }

}
