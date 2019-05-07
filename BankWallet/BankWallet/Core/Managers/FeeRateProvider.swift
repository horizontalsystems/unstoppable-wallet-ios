import FeeRateKit

class FeeRateProvider {
    let feeRateKit = FeeRateKit.instance()

    private func feeRate(from feeRate: FeeRate, priority: FeeRatePriority) -> Int {
        switch priority {
        case .lowest:
            return feeRate.lowPriority
        case .low:
            return (feeRate.lowPriority + feeRate.mediumPriority) / 2
        case .medium:
            return feeRate.mediumPriority
        case .high:
            return (feeRate.mediumPriority + feeRate.highPriority) / 2
        case .highest:
            return feeRate.highPriority
        }
    }
}

extension FeeRateProvider: IFeeRateProvider {

    func ethereumGasPrice(for priority: FeeRatePriority) -> Int {
        return feeRate(from: feeRateKit.ethereum, priority: priority)
    }

    func bitcoinFeeRate(for priority: FeeRatePriority) -> Int {
        return feeRate(from: feeRateKit.bitcoin, priority: priority)
    }

    func bitcoinCashFeeRate(for priority: FeeRatePriority) -> Int {
        return feeRate(from: feeRateKit.bitcoinCash, priority: priority)
    }

    func dashFeeRate(for priority: FeeRatePriority) -> Int {
        return feeRate(from: feeRateKit.dash, priority: priority)
    }

}
