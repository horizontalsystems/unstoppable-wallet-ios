import MarketKit

class FeeRateProviderFactory {
    private let feeRateProvider: FeeRateProvider

    init(appConfigProvider: AppConfigProvider) {
        feeRateProvider = FeeRateProvider(appConfigProvider: appConfigProvider)
    }

    func provider(blockchainType: BlockchainType) -> IFeeRateProvider? {
        switch blockchainType {
        case .bitcoin: return BitcoinFeeRateProvider(feeRateProvider: feeRateProvider)
        case .litecoin: return LitecoinFeeRateProvider(feeRateProvider: feeRateProvider)
        case .bitcoinCash: return BitcoinCashFeeRateProvider(feeRateProvider: feeRateProvider)
        case .dash: return DashFeeRateProvider(feeRateProvider: feeRateProvider)
        case .ethereum: return EthereumFeeRateProvider(feeRateProvider: feeRateProvider)
        case .binanceSmartChain: return BinanceSmartChainFeeRateProvider(feeRateProvider: feeRateProvider)
        default: return nil
        }
    }

    func forcedProvider(blockchainType: BlockchainType, customFeeRange: ClosedRange<Int>, multiply: Double) -> ICustomRangedFeeRateProvider? {
        switch blockchainType {
        case .ethereum: return EthereumFeeRateProvider(feeRateProvider: feeRateProvider, customFeeRange: customFeeRange, multiply: multiply)
        case .binanceSmartChain: return BinanceSmartChainFeeRateProvider(feeRateProvider: feeRateProvider, customFeeRange: customFeeRange, multiply: multiply)
        default: return nil
        }
    }

}
