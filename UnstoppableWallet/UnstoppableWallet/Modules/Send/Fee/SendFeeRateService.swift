import RxSwift
import RxRelay
import RxCocoa

class SendFeeRateService {
    private let disposeBag = DisposeBag()
    private var feeRateDisposeBag = DisposeBag()
    private let provider: IFeeRateProvider

    private let feeRateRelay = BehaviorRelay<DataStatus<Int>>(value: .loading)
    private(set) var feeRate: DataStatus<Int> = .loading {
        didSet {
            feeRateRelay.accept(feeRate)
        }
    }

    private let recommendedFeeRateRelay = BehaviorRelay<Int?>(value: nil)
    var recommendedFeeRate: Int? {
        didSet {
            recommendedFeeRateRelay.accept(recommendedFeeRate)
        }
    }

    init(provider: IFeeRateProvider) {
        self.provider = provider
    }

}

extension SendFeeRateService {

    var staticFeeRate: Bool {
        false
//        priorityService.feeRatePriorityList.isEmpty
    }

    var feeRateObservable: Observable<DataStatus<Int>> {
        feeRateRelay.asObservable()
    }

    var recommendedFeeRateObservable: Observable<Int?> {
        recommendedFeeRateRelay.asObservable()
    }

}
