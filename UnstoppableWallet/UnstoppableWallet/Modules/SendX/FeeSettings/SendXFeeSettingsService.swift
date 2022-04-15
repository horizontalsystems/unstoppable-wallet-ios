import Foundation
import RxSwift
import RxRelay

class SendXFeeSettingsService {
    private let disposeBag = DisposeBag()

    private let feeService: SendFeeService
    private let feeRateService: SendXFeeRateService
    private let feePriorityService: SendXFeePriorityService

    private let isInitialPriorityRelay = BehaviorRelay<Bool>(value: true)
    private let initialPriority: FeeRatePriority

    init(feeService: SendFeeService, feeRateService: SendXFeeRateService, feePriorityService: SendXFeePriorityService) {
        self.feeService = feeService
        self.feeRateService = feeRateService
        self.feePriorityService = feePriorityService

        initialPriority = feePriorityService.defaultFeeRatePriority
        subscribe(disposeBag, feePriorityService.priorityObservable) { [weak self] in self?.sync(priority: $0) }

        sync(priority: feePriorityService.priority)
    }

    private func sync(priority: FeeRatePriority) {
        isInitialPriorityRelay.accept(priority == initialPriority)
    }

}

extension SendXFeeSettingsService {

    var isInitialPriorityObservable: Observable<Bool> {
        isInitialPriorityRelay.asObservable()
    }

    func reset() {
        feePriorityService.priority = initialPriority
    }

}