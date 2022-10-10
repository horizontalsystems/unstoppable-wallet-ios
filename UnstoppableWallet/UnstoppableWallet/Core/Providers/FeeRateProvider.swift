import Foundation
import FeeRateKit
import RxSwift

class FeeRateProvider {
    private let feeRateKit: FeeRateKit.Kit

    init(appConfigProvider: AppConfigProvider) {
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

class BitcoinFeeRateProvider: ICustomRangedFeeRateProvider {
    static let defaultFeeRange: ClosedRange<Int> = 1...200
    let customFeeRange: ClosedRange<Int> = BitcoinFeeRateProvider.defaultFeeRange
    let step: Int = 1

    private let feeRateProvider: FeeRateProvider
    private let lowPriorityBlockCount = 6
    private let mediumPriorityBlockCount = 2
    private let highPriorityBlockCount = 1

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var feeRatePriorityList: [FeeRatePriority] {
        [
            .low,
            .recommended,
            .high,
            .custom(value: customFeeRange.lowerBound, range: customFeeRange)
        ]
    }
    var recommendedFeeRate: Single<Int> { feeRateProvider.bitcoinFeeRate(blockCount: mediumPriorityBlockCount) }

    var defaultFeeRatePriority: FeeRatePriority {
        .recommended
    }

    func feeRate(priority: FeeRatePriority) -> Single<Int> {
        switch priority {
        case .low:
            return feeRateProvider.bitcoinFeeRate(blockCount: lowPriorityBlockCount)
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

private func ceil(_ value: Int, multiply: Double?) -> Int {
    guard let multiply = multiply else {
        return value
    }
    return Int(ceil(Double(value) * multiply))
}
