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

    func ethereumGasPrice(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateKit.ethereum.map { FeeRate(feeRate: $0) }
    }

    func bitcoinFeeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateKit.bitcoin.map { FeeRate(feeRate: $0) }
    }

    func bitcoinCashFeeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateKit.bitcoinCash.map { FeeRate(feeRate: $0) }
    }

    func dashFeeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateKit.dash.map { FeeRate(feeRate: $0) }
    }

}

class BitcoinFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateProvider.bitcoinFeeRate(for: priority)
    }

}

class BitcoinCashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateProvider.bitcoinCashFeeRate(for: priority)
    }

}

class EthereumFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateProvider.ethereumGasPrice(for: priority)
    }

}

class DashFeeRateProvider: IFeeRateProvider {
    private let feeRateProvider: FeeRateProvider

    init(feeRateProvider: FeeRateProvider) {
        self.feeRateProvider = feeRateProvider
    }

    func feeRate(for priority: FeeRatePriority) -> Single<FeeRate> {
        feeRateProvider.dashFeeRate(for: priority)
    }

}
