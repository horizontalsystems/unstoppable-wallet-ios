import RxSwift
import RxRelay
import RxCocoa

class FeeRateService {
    private var disposeBag = DisposeBag()

    private let provider: IFeeRateProvider

    private(set) var recommendedFeeRate: Int = 0
    private var feeRate = 0 {
        didSet {
            status = .completed(feeRate)
        }
    }

    var usingRecommended = true { didSet { usingRecommendedRelay.accept(usingRecommended) } }
    private let usingRecommendedRelay = PublishRelay<Bool>()

    private let statusRelay = PublishRelay<DataStatus<Int>>()
    private(set) var status: DataStatus<Int> = .loading {
        didSet {
            statusRelay.accept(status)
        }
    }

    init(provider: IFeeRateProvider) {
        self.provider = provider

        setRecommendedFeeRate()
    }

}

extension FeeRateService {

    var statusObservable: Observable<DataStatus<Int>> {
        statusRelay.asObservable()
    }

    var usingRecommendedObservable: Observable<Bool> {
        usingRecommendedRelay.asObservable()
    }

    func set(feeRate: Int) {
        self.feeRate = feeRate
        usingRecommended = false
    }

    func setRecommendedFeeRate() {
        disposeBag = DisposeBag()

        status = .loading

        provider.recommendedFeeRate
                .subscribe(
                        onSuccess: { [weak self] feeRate in
                            self?.recommendedFeeRate = feeRate
                            self?.feeRate = feeRate
                            self?.usingRecommended = true
                        },
                        onError: { [weak self] error in
                            self?.status = .failed(error)
                        }
                )
                .disposed(by: disposeBag)
    }

}
