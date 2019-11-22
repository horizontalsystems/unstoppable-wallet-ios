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
        provider.feeRate(for: priority)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: delegate?.didUpdate, onError: delegate?.didReceiveError)
                .disposed(by: disposeBag)
    }

}
