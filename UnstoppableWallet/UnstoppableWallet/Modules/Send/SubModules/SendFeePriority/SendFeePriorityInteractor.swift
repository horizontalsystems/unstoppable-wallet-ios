import Foundation
import RxSwift

class SendFeePriorityInteractor {
    var delegate: ISendFeePriorityInteractorDelegate?

    private var disposeBag = DisposeBag()
    private let provider: IFeeRateProvider

    init(provider: IFeeRateProvider) {
        self.provider = provider
    }

}

extension SendFeePriorityInteractor: ISendFeePriorityInteractor {

    func syncFeeRate(priority: FeeRatePriority) {
        disposeBag = DisposeBag()
        provider.feeRate(priority: priority)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: delegate?.didUpdate, onError: delegate?.didReceiveError)
                .disposed(by: disposeBag)
    }


    var feeRatePriorityList: [FeeRatePriority] {
        provider.feeRatePriorityList
    }

    var defaultFeeRatePriority: FeeRatePriority {
        provider.defaultFeeRatePriority
    }

}
