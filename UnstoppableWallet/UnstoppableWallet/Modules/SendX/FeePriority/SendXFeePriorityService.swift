import RxSwift
import RxRelay
import RxCocoa

class SendXFeePriorityService {
    private var disposeBag = DisposeBag()
    private let provider: IFeeRateProvider

    private let priorityRelay = BehaviorRelay<FeeRatePriority>(value: .recommended)
    var priority: FeeRatePriority {
        didSet {
            if oldValue != priority {
                priorityRelay.accept(priority)
            }
        }
    }

    init(provider: IFeeRateProvider) {
        self.provider = provider

        priority = provider.defaultFeeRatePriority
    }

    deinit {
        print("Deinit \(self)")
    }

}

extension SendXFeePriorityService {

    var priorityObservable: Observable<FeeRatePriority> {
        priorityRelay.asObservable()
    }

    var feeRatePriorityList: [FeeRatePriority] {
        provider.feeRatePriorityList
    }

    func isRecommended(priority: FeeRatePriority) -> Bool {
        priority == .medium || priority == .recommended
    }

}
