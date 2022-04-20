import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class SendBitcoinFeeService: SendFeeService {
    private let feePriorityService: SendFeePriorityService

    init(fiatService: FiatService, feePriorityService: SendFeePriorityService, feeCoin: PlatformCoin) {
        self.feePriorityService = feePriorityService

        super.init(fiatService: fiatService, feeCoin: feeCoin)
    }

    override var defaultFeeObservable: Observable<Bool> {
        feePriorityService.defaultPriorityObservable
    }

}
