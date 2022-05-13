import RxSwift
import RxRelay
import RxCocoa

class SendFeePriorityService {
    private let provider: IFeeRateProvider
    weak var feeRateService: SendFeeRateService?

    private let priorityRelay = BehaviorRelay<FeeRatePriority>(value: .recommended)
    var priority: FeeRatePriority {
        didSet {
            update(priority: priority, old: oldValue)
        }
    }

    private let defaultPriorityRelay = BehaviorRelay<Bool>(value: true)
    var defaultPriority: Bool = true {
        didSet {
            defaultPriorityRelay.accept(defaultPriority)
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

        defaultPriorityRelay.accept(provider.defaultFeeRatePriority == priority)

        priorityRelay.accept(self.priority)
    }

}

extension SendFeePriorityService {

    var priorityObservable: Observable<FeeRatePriority> {
        priorityRelay.asObservable()
    }

    var defaultPriorityObservable: Observable<Bool> {
        defaultPriorityRelay.asObservable()
    }

    var feeRatePriorityList: [FeeRatePriority] {
        provider.feeRatePriorityList
    }

    var defaultFeeRatePriority: FeeRatePriority {
        provider.defaultFeeRatePriority
    }

    func isRecommended(priority: FeeRatePriority) -> Bool {
        priority == .recommended
    }

}
