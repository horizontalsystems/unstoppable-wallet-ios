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
                btcCoreRpcUrl: AppConfig.btcCoreRpcUrl,
                btcCoreRpcUser: nil,
                btcCoreRpcPassword: nil
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

    var litecoinFeeRate: Int {
        feeRateKit.litecoin
    }

    var bitcoinCashFeeRate: Int {
        feeRateKit.bitcoinCash
    }

    var dashFeeRate: Int {
        feeRateKit.dash
    }

    func bitcoinFeeRate(blockCount: Int) async throws -> Int {
        try await feeRateKit.bitcoin(blockCount: blockCount)
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

    func recommendedFeeRate() async throws -> Int {
        try await feeRateProvider.bitcoinFeeRate(blockCount: recommendedBlockCount)
    }

}

class LitecoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func recommendedFeeRate() async throws -> Int {
        feeRateProvider.litecoinFeeRate
    }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func recommendedFeeRate() async throws -> Int {
        feeRateProvider.bitcoinCashFeeRate
    }

}

class ECashFeeRateProvider: IFeeRateProvider {

    func recommendedFeeRate() async throws -> Int {
        1
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func recommendedFeeRate() async throws -> Int {
        feeRateProvider.dashFeeRate
    }

}

private func ceil(_ value: Int, multiply: Double?) -> Int {
    guard let multiply = multiply else {
        return value
    }
    return Int(ceil(Double(value) * multiply))
}
