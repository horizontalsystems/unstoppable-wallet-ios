import EvmKit
import RxSwift
import RxCocoa

class NonceService {
    private var disposeBag = DisposeBag()
    private let evmKit: EvmKit.Kit

    private(set) var minimumNonce: Int = 0
    private(set) var recommendedNonce: Int = 0
    private(set) var nonce: Int = 0 {
        didSet {
            sync()
        }
    }
    let frozen: Bool

    var usingRecommended = true { didSet { usingRecommendedRelay.accept(usingRecommended) } }
    private let usingRecommendedRelay = PublishRelay<Bool>()

    private let statusRelay = PublishRelay<DataStatus<FallibleData<Int>>>()
    private(set) var status: DataStatus<FallibleData<Int>> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(evmKit: EvmKit.Kit, replacingNonce: Int?) {
        self.evmKit = evmKit

        if let nonce = replacingNonce {
            self.nonce = nonce
            frozen = true

            status = .completed(FallibleData(data: nonce, errors: [], warnings: []))
        } else {
            frozen = false
        }

        resetNonce()
    }

    private func sync() {
        var errors: [NonceError] = []

        if nonce < minimumNonce {
            errors.append(.alreadyInUse)
        }

        status = .completed(FallibleData(data: nonce, errors: errors, warnings: []))
    }

}

extension NonceService {

    var statusObservable: Observable<DataStatus<FallibleData<Int>>> {
        statusRelay.asObservable()
    }

    var usingRecommendedObservable: Observable<Bool> {
        usingRecommendedRelay.asObservable()
    }

    func set(nonce: Int) {
        self.nonce = nonce
        usingRecommended = false
    }

    func resetNonce() {
        guard !frozen else {
            return
        }

        disposeBag = DisposeBag()

        status = .loading

        Single.zip(evmKit.nonceSingle(defaultBlockParameter: .pending), evmKit.nonceSingle(defaultBlockParameter: .latest))
                .subscribe(
                        onSuccess: { [weak self] noncePending, nonceLatest in
                            self?.minimumNonce = nonceLatest
                            self?.recommendedNonce = noncePending
                            self?.usingRecommended = true
                            self?.nonce = noncePending
                        },
                        onError: { [weak self] error in
                            self?.status = .failed(error)
                        }
                )
                .disposed(by: disposeBag)
    }

}

extension NonceService {

    enum NonceError: Error {
        case alreadyInUse
    }

}
