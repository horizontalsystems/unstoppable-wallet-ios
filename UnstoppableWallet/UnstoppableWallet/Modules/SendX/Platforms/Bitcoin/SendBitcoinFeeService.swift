import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class SendBitcoinFeeService: SendFeeService {
    private let feePriorityService: SendXFeePriorityService

    init(fiatService: FiatService, feePriorityService: SendXFeePriorityService, feeCoin: PlatformCoin) {
        self.feePriorityService = feePriorityService

        super.init(fiatService: fiatService, feeCoin: feeCoin)
    }

    override var defaultFeeObservable: Observable<Bool> {
        feePriorityService.defaultPriorityObservable
    }

}
