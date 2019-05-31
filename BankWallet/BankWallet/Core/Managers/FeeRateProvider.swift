import FeeRateKit

class FeeRateProvider {
    let feeRateKit = FeeRateKit.instance()

    private func feeRate(from feeRate: FeeRate, priority: FeeRatePriority) -> Int {
        switch priority {
        case .lowest:
            return feeRate.low
        case .low:
            return (feeRate.low + feeRate.medium) / 2
        case .medium:
            return feeRate.medium
        case .high:
            return (feeRate.medium + feeRate.high) / 2
        case .highest:
            return feeRate.high
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
