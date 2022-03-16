import RxSwift
import RxRelay
import RxCocoa

class SendXFeePriorityService {
    private var disposeBag = DisposeBag()
    private let provider: IFeeRateProvider
    weak var feeRateService: SendXFeeRateService?

    private let priorityRelay = BehaviorRelay<FeeRatePriority>(value: .recommended)
    var priority: FeeRatePriority {
        didSet {
            update(priority: priority, old: oldValue)
        }
    }

    init(provider: IFeeRateProvider) {
        self.provider = provider

        priority = provider.defaultFeeRatePriority
    }

    private func update(priority: FeeRatePriority, old: FeeRatePriority) {
        guard old != priority else {
            return
        }

        // when change to custom fee priority we need set position by last feeRate for slider
        if !old.isCustom,
           case let .custom(value, range) = priority {

            self.priority = .custom(value: feeRateService?.feeRate.data ?? value, range: range)
        }

        priorityRelay.accept(self.priority)
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
