import FeeRateKit
import RxSwift

class FeeRateProvider {
    private let feeRateKit: FeeRateKit.Kit

    init(appConfigProvider: IAppConfigProvider) {
        let providerConfig = FeeProviderConfig(
                ethEvmUrl: FeeProviderConfig.infuraUrl(projectId: appConfigProvider.infuraCredentials.id),
                ethEvmAuth: appConfigProvider.infuraCredentials.secret,
                bscEvmUrl: FeeProviderConfig.defaultBscEvmUrl,
                btcCoreRpcUrl: appConfigProvider.btcCoreRpcUrl,
                btcCoreRpcUser: nil,
                btcCoreRpcPassword: nil
        )
        feeRateKit = FeeRateKit.Kit.instance(providerConfig: providerConfig, minLogLevel: .error)
    }

    // Fee rates

    var ethereumGasPrice: Single<Int> {
        feeRateKit.ethereum
    }

    var binanceSmartChainGasPrice: Single<Int> {
        feeRateKit.binanceSmartChain
    }

    var litecoinFeeRate: Single<Int> {
        feeRateKit.litecoin
    }

    var bitcoinCashFeeRate: Single<Int> {
        feeRateKit.bitcoinCash
    }

    var dashFeeRate: Single<Int> {
        feeRateKit.dash
    }

    func bitcoinFeeRate(blockCount: Int) -> Single<Int> {
        feeRateKit.bitcoin(blockCount: blockCount)
    }

}

class BitcoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider
    private let lowPriorityBlockCount = 40
    private let mediumPriorityBlockCount = 8
    private let highPriorityBlockCount = 2

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRatePriorityList: [FeeRatePriority] {
        [
            .low,
            .medium,
            .high,
            .custom(value: 1, range: 1...200)
        ]
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.bitcoinFeeRate(blockCount: mediumPriorityBlockCount) }

    var defaultFeeRatePriority: FeeRatePriority {
        .medium
    }

    func feeRate(priority: FeeRatePriority) -> Single<Int> {
        switch priority {
        case .low:
            return feeRateProvider.bitcoinFeeRate(blockCount: lowPriorityBlockCount)
        case .medium:
            return feeRateProvider.bitcoinFeeRate(blockCount: mediumPriorityBlockCount)
        case .high:
            return feeRateProvider.bitcoinFeeRate(blockCount: highPriorityBlockCount)
        case .recommended:
            return feeRateProvider.bitcoinFeeRate(blockCount: mediumPriorityBlockCount)
        case let .custom(value, _):
            return Single.just(value)
        }
    }

}

class LitecoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.litecoinFeeRate }
    var feeRatePriorityList: [FeeRatePriority] = []

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.bitcoinCashFeeRate }
    var feeRatePriorityList: [FeeRatePriority] = []

}

class EthereumFeeRateProvider: IFeeRateProvider {
    private let lower = 1_000_000_000
    private let upper = 400_000_000_000

    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.ethereumGasPrice }
    var feeRatePriorityList: [FeeRatePriority] {
        [.recommended, .custom(value: lower, range: lower...upper)]
    }

}

class BinanceSmartChainFeeRateProvider: IFeeRateProvider {
    private let lower = 1_000_000_000
    private let upper = 400_000_000_000

    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.binanceSmartChainGasPrice }
    var feeRatePriorityList: [FeeRatePriority] {
        [.recommended, .custom(value: lower, range: lower...upper)]
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.dashFeeRate }
    var feeRatePriorityList: [FeeRatePriority] = []
}

extension IFeeRateProvider {

    var feeRatePriorityList: [FeeRatePriority] {
        [.recommended]
    }

    var defaultFeeRatePriority: FeeRatePriority {
        .recommended
    }

    func feeRate(priority: FeeRatePriority) -> Single<Int> {
        if case let .custom(value, _) = priority {
            return Single.just(value)
        }

        return recommendedFeeRate
    }

}
