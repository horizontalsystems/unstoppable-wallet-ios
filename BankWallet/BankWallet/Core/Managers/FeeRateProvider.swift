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

    private func transactionSendDuration(from feeRate: FeeRate, priority: FeeRatePriority) -> TimeInterval {
        // TODO: FeeRate will store these values
        switch priority {
        case .low:
            return 3600 * 12
        case .medium:
            return 3600 * 4
        case .high:
            return 3600
        }
    }

    // Fee rates

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


    // Transaction inclusion in block durations

    func bitcoinTransactionSendDuration(for priority: FeeRatePriority) -> TimeInterval {
        return transactionSendDuration(from: feeRateKit.bitcoin, priority: priority)
    }

    func bitcoinCashTransactionSendDuration(for priority: FeeRatePriority) -> TimeInterval {
        return transactionSendDuration(from: feeRateKit.bitcoinCash, priority: priority)
    }

    func dashTransactionSendDuration(for priority: FeeRatePriority) -> TimeInterval {
        return transactionSendDuration(from: feeRateKit.dash, priority: priority)
    }

    func ethereumTransactionSendDuration(for priority: FeeRatePriority) -> TimeInterval {
        return transactionSendDuration(from: feeRateKit.ethereum, priority: priority)
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

    func duration(priority: FeeRatePriority) -> TimeInterval {
        return feeRateProvider.bitcoinTransactionSendDuration(for: priority)
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

    func duration(priority: FeeRatePriority) -> TimeInterval {
        return feeRateProvider.bitcoinCashTransactionSendDuration(for: priority)
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

    func duration(priority: FeeRatePriority) -> TimeInterval {
        return feeRateProvider.ethereumTransactionSendDuration(for: priority)
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

    func duration(priority: FeeRatePriority) -> TimeInterval {
        return feeRateProvider.dashTransactionSendDuration(for: priority)
    }

}
