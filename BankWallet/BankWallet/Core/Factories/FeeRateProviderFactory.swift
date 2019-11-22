class FeeRateProviderFactory {
    private let feeRateProvider: FeeRateProvider

    init(appConfigProvider: IAppConfigProvider) {
        feeRateProvider = FeeRateProvider(appConfigProvider: appConfigProvider)
    }

    func provider(coin: Coin) -> IFeeRateProvider? {
        switch coin.type {
        case .bitcoin: return BitcoinFeeRateProvider(feeRateProvider: feeRateProvider)
        case .bitcoinCash: return BitcoinCashFeeRateProvider(feeRateProvider: feeRateProvider)
        case .dash: return DashFeeRateProvider(feeRateProvider: feeRateProvider)
        case .ethereum, .erc20: return EthereumFeeRateProvider(feeRateProvider: feeRateProvider)
        default: return nil
        }
    }

}
