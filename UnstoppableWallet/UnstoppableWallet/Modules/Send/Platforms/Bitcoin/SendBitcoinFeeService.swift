import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class SendBitcoinFeeService: SendFeeService {

    override var defaultFeeObservable: Observable<Bool> {
        Observable.just(true)
//        feePriorityService.defaultPriorityObservable
    }

}
