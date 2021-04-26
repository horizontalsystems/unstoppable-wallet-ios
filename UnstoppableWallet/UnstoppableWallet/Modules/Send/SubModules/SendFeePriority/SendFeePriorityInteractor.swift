import Foundation
import RxSwift
import CurrencyKit

class SendFeePriorityInteractor {
    var delegate: ISendFeePriorityInteractorDelegate?

    private var disposeBag = DisposeBag()
    private let provider: IFeeRateProvider
    private let currencyKit: CurrencyKit.Kit

    init(provider: IFeeRateProvider, currencyKit: CurrencyKit.Kit) {
        self.provider = provider
        self.currencyKit = currencyKit
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

    var baseCurrency: Currency {
        currencyKit.baseCurrency
    }

}
