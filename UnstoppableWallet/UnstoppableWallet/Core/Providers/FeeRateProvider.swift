import Foundation
import FeeRateKit
import RxSwift

class FeeRateProvider {
    private let feeRateKit: FeeRateKit.Kit

    init() {
        let providerConfig = FeeProviderConfig(
                ethEvmUrl: FeeProviderConfig.infuraUrl(projectId: AppConfig.infuraCredentials.id),
                ethEvmAuth: AppConfig.infuraCredentials.secret,
                bscEvmUrl: FeeProviderConfig.defaultBscEvmUrl,
                mempoolSpaceUrl: AppConfig.mempoolSpaceUrl
        )
        feeRateKit = FeeRateKit.Kit.instance(providerConfig: providerConfig, minLogLevel: .error)
    }

    // Fee rates

//    var ethereumGasPrice: Single<Int> {
//        feeRateKit.ethereum
//    }

//    var binanceSmartChainGasPrice: Single<Int> {
//        feeRateKit.binanceSmartChain
//    }

    fileprivate var litecoinFeeRate: Int {
        feeRateKit.litecoin
    }

    fileprivate var bitcoinCashFeeRate: Int {
        feeRateKit.bitcoinCash
    }

    fileprivate var dashFeeRate: Int {
        feeRateKit.dash
    }

    fileprivate func bitcoinFeeRate() async throws -> MempoolSpaceProvider.RecommendedFees {
        try await feeRateKit.bitcoin()
    }

}

extension FeeRateProvider {

    struct FeeRates {
        let recommended: Int
        let minimum: Int
    }

}

class BitcoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRates() async throws -> FeeRateProvider.FeeRates {
        let rates = try await feeRateProvider.bitcoinFeeRate()
        return .init(recommended: rates.halfHourFee, minimum: rates.minimumFee)
    }

}

class LitecoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRates() async throws -> FeeRateProvider.FeeRates {
        .init(recommended: feeRateProvider.litecoinFeeRate, minimum: 0)
    }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRates() async throws -> FeeRateProvider.FeeRates {
        .init(recommended: feeRateProvider.bitcoinCashFeeRate, minimum: 0)
    }

}

class ECashFeeRateProvider: IFeeRateProvider {

    func feeRates() async throws -> FeeRateProvider.FeeRates {
        .init(recommended: 1, minimum: 0)
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRates() async throws -> FeeRateProvider.FeeRates {
        .init(recommended: feeRateProvider.dashFeeRate, minimum: 0)
    }

}

private func ceil(_ value: Int, multiply: Double?) -> Int {
    guard let multiply = multiply else {
        return value
    }
    return Int(ceil(Double(value) * multiply))
}
