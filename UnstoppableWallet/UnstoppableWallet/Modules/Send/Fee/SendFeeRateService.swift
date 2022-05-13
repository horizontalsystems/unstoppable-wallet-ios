import RxSwift
import RxRelay
import RxCocoa

class SendFeeRateService {
    private let disposeBag = DisposeBag()
    private var feeRateDisposeBag = DisposeBag()
    private let provider: IFeeRateProvider
    private let priorityService: SendFeePriorityService

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

    init(priorityService: SendFeePriorityService, provider: IFeeRateProvider) {
        self.priorityService = priorityService
        self.provider = provider

        subscribe(disposeBag, provider.feeRateUpdatedObservable) { [weak self] _ in self?.updateFeeRate() }
        subscribe(disposeBag, priorityService.priorityObservable) { [weak self] in self?.updateFeeRate(priority: $0) }
    }

    private func updateFeeRate(priority: FeeRatePriority? = nil) {
        let priority = priority ?? priorityService.priority

        feeRateDisposeBag = DisposeBag()
        feeRate = .loading

        provider.feeRate(priority: priority)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] feeRate in
                    self?.sync(feeRate: feeRate, priority: priority)
                }, onError: { [weak self] error in
                    self?.feeRate = .failed(error)
                })
                .disposed(by: feeRateDisposeBag)
    }

    private func sync(feeRate: Int, priority: FeeRatePriority) {
        if priorityService.isRecommended(priority: priority) {
            recommendedFeeRate = feeRate
        }

        self.feeRate = .completed(feeRate)
    }

}

extension SendFeeRateService {

    var staticFeeRate: Bool {
        priorityService.feeRatePriorityList.isEmpty
    }

    var feeRateObservable: Observable<DataStatus<Int>> {
        feeRateRelay.asObservable()
    }

    var recommendedFeeRateObservable: Observable<Int?> {
        recommendedFeeRateRelay.asObservable()
    }

}
