import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class SendBitcoinFeeService: SendFeeService {
    private let feePriorityService: SendFeePriorityService

    init(fiatService: FiatService, feePriorityService: SendFeePriorityService, feeToken: Token) {
        self.feePriorityService = feePriorityService

        super.init(fiatService: fiatService, feeToken: feeToken)
    }

    override var defaultFeeObservable: Observable<Bool> {
        feePriorityService.defaultPriorityObservable
    }

}
