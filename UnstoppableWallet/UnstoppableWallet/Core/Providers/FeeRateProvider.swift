import FeeRateKit
import RxSwift

class FeeRateProvider {
    private let feeRateKit: FeeRateKit.Kit

    init(appConfigProvider: IAppConfigProvider) {
        let providerConfig = FeeProviderConfig(infuraProjectId: appConfigProvider.infuraCredentials.id,
                infuraProjectSecret: appConfigProvider.infuraCredentials.secret,
                btcCoreRpcUrl: appConfigProvider.btcCoreRpcUrl,
                btcCoreRpcUser: nil,
                btcCoreRpcPassword: nil
        )
        feeRateKit = FeeRateKit.Kit.instance(providerConfig: providerConfig, minLogLevel: .error)
    }

    // Fee rates

    var ethereumGasPrice: Single<FeeRate> {
        feeRateKit.ethereum.map { FeeRate(feeRate: $0) }
    }

    var bitcoinFeeRate: Single<FeeRate> {
        feeRateKit.bitcoin.map { FeeRate(feeRate: $0) }
    }

    var litecoinFeeRate: Single<FeeRate> {
        feeRateKit.litecoin.map { FeeRate(feeRate: $0) }
    }

    var bitcoinCashFeeRate: Single<FeeRate> {
        feeRateKit.bitcoinCash.map { FeeRate(feeRate: $0) }
    }

    var dashFeeRate: Single<FeeRate> {
        feeRateKit.dash.map { FeeRate(feeRate: $0) }
    }

}

class BitcoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRate: Single<FeeRate> {
        feeRateProvider.bitcoinFeeRate
    }

    var feeRatePriorityList: [FeeRatePriority] {
        [.low, .medium, .high, .custom(value: 1, range: 1...200)]
    }

}

class LitecoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRate: Single<FeeRate> {
        feeRateProvider.litecoinFeeRate
    }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRate: Single<FeeRate> {
        feeRateProvider.bitcoinCashFeeRate
    }

}

class EthereumFeeRateProvider: IFeeRateProvider {
    private let lower = 1_000_000_000
    private let upper = 400_000_000_000

    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRatePriorityList: [FeeRatePriority] {
        [.recommended, .custom(value: lower, range: lower...upper)]
    }

    var feeRate: Single<FeeRate> {
        feeRateProvider.ethereumGasPrice
    }

    var defaultFeeRatePriority: FeeRatePriority {
        .recommended
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRate: Single<FeeRate> {
        feeRateProvider.dashFeeRate
    }

    private(set) var feeRatePriorityList: [FeeRatePriority] = []
}

extension IFeeRateProvider {

    var feeRatePriorityList: [FeeRatePriority] {
        [.low, .medium, .high]
    }

    var defaultFeeRatePriority: FeeRatePriority {
        .medium
    }

}