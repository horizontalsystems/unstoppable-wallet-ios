import FeeRateKit

class FeeRateProvider {
    let feeRateKit = FeeRateKit.instance()

    private func feeRate(from feeRate: FeeRate, priority: FeeRatePriority) -> Int {
        switch priority {
        case .low:
            return feeRate.low
        case .medium:
            return feeRate.medium
        case .high:
            return feeRate.high
        }
    }

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

class BitcoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Int {
        return feeRateProvider.bitcoinFeeRate(for: priority)
    }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Int {
        return feeRateProvider.bitcoinCashFeeRate(for: priority)
    }

}

class EthereumFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Int {
        return feeRateProvider.ethereumGasPrice(for: priority)
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Int {
        return feeRateProvider.dashFeeRate(for: priority)
    }

}
