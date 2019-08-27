import Foundation

class SendFeePriorityInteractor {
    private let provider: IFeeRateProvider

    init(provider: IFeeRateProvider) {
        self.provider = provider
    }

}

extension SendFeePriorityInteractor: ISendFeePriorityInteractor {

    func feeRate(priority: FeeRatePriority) -> Int {
        return provider.feeRate(for: priority)
    }

    func duration(priority: FeeRatePriority) -> TimeInterval {
        return provider.duration(priority: priority)
    }

}
