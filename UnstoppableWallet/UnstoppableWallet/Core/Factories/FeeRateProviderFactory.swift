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
        default: return nil
        }
    }

}
