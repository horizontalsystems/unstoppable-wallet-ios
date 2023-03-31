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
    private let recommendedBlockCount = 2

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }
    var recommendedFeeRate: Single<Int> { feeRateProvider.bitcoinFeeRate(blockCount: recommendedBlockCount) }

}

class LitecoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.litecoinFeeRate }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.bitcoinCashFeeRate }

}

class ECashFeeRateProvider: IFeeRateProvider {
    var recommendedFeeRate: Single<Int> { .just(1) }
}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    var recommendedFeeRate: Single<Int> { feeRateProvider.dashFeeRate }
}

private func ceil(_ value: Int, multiply: Double?) -> Int {
    guard let multiply = multiply else {
        return value
    }
    return Int(ceil(Double(value) * multiply))
}
