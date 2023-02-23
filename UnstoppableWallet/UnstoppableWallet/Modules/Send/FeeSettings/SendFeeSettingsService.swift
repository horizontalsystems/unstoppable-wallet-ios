import Foundation
import RxSwift
import RxRelay

class SendFeeSettingsService {
    private let disposeBag = DisposeBag()

    private let defaultFeeRateRelay = BehaviorRelay<Bool>(value: true)

}

extension SendFeeSettingsService {

    var defaultFeeRateObservable: Observable<Bool> {
        defaultFeeRateRelay.asObservable()
    }

    func reset() {
        // Set recommended feeRate here
    }

}
