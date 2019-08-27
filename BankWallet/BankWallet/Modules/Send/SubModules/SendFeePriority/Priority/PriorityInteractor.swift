import Foundation

class PriorityInteractor {
    let feeRateProvider: IFeeRateProvider

    init(feeRateProvider: IFeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

}

extension PriorityInteractor: IPriorityInteractor {

    func duration(priority: FeeRatePriority) -> TimeInterval {
        return feeRateProvider.duration(priority: priority)
    }

}
