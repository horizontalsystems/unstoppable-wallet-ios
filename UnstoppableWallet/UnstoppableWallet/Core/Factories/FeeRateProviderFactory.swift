import MarketKit

class FeeRateProviderFactory {
    private let feeRateProvider: FeeRateProvider

    init(appConfigProvider: IAppConfigProvider) {
        feeRateProvider = FeeRateProvider(appConfigProvider: appConfigProvider)
    }

    func provider(coinType: CoinType) -> IFeeRateProvider? {
        switch coinType {
        case .bitcoin: return BitcoinFeeRateProvider(feeRateProvider: feeRateProvider)
        case .litecoin: return LitecoinFeeRateProvider(feeRateProvider: feeRateProvider)
        case .bitcoinCash: return BitcoinCashFeeRateProvider(feeRateProvider: feeRateProvider)
        case .dash: return DashFeeRateProvider(feeRateProvider: feeRateProvider)
        case .ethereum: return EthereumFeeRateProvider(feeRateProvider: feeRateProvider)
        case .binanceSmartChain: return BinanceSmartChainFeeRateProvider(feeRateProvider: feeRateProvider)
        default: return nil
        }
    }

    func forcedProvider(coinType: CoinType, customFeeRange: ClosedRange<Int>, multiply: Double) -> ICustomRangedFeeRateProvider? {
        switch coinType {
        case .ethereum: return EthereumFeeRateProvider(feeRateProvider: feeRateProvider, customFeeRange: customFeeRange, multiply: multiply)
        case .binanceSmartChain: return BinanceSmartChainFeeRateProvider(feeRateProvider: feeRateProvider, customFeeRange: customFeeRange, multiply: multiply)
        default: return nil
        }
    }

}
