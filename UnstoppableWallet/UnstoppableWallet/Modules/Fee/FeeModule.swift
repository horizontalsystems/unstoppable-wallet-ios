import Foundation
import EthereumKit

struct FeeModule {

    static func instance(erc20Adapter: IErc20Adapter, coin: Coin, amount: Decimal, spenderAddress: Address) -> FeePresenter? {
        let feeCoin = App.shared.feeCoinProvider.feeCoin(coin: coin) ?? coin

        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: feeCoin.type) else {
            return nil
        }

        let interactor = FeeService(adapter: erc20Adapter, provider: feeRateProvider, rateManager: App.shared.rateManager, baseCurrency: App.shared.currencyKit.baseCurrency, feeCoin: feeCoin, amount: amount, spenderAddress: spenderAddress)
        let presenter = FeePresenter(service: interactor)

        return presenter
    }

}

extension FeeModule {

    enum FeeError: Error, LocalizedError {
        case insufficientFeeBalance(coinValue: CoinValue)

        var errorDescription: String? {
            switch self {
            case let .insufficientFeeBalance(coinValue):
                return "swap.error.insufficient_fee_alert".localized(coinValue.coin.title, ValueFormatter.instance.format(coinValue: coinValue) ?? "")
            }
        }
    }

}
