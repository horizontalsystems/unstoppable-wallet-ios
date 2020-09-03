import Foundation
import EthereumKit

struct FeeModule {

    static func instance(erc20Adapter: IErc20Adapter, coin: Coin, amount: Decimal, spenderAddress: Address) -> FeePresenter? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin) else {
            return nil
        }

        let feeCoinProvider = App.shared.feeCoinProvider
        let feeCoin = feeCoinProvider.feeCoin(coin: coin) ?? coin

        let interactor = FeeService(adapter: erc20Adapter, provider: feeRateProvider, rateManager: App.shared.rateManager, baseCurrency: App.shared.currencyKit.baseCurrency, feeCoin: feeCoin, amount: amount, spenderAddress: spenderAddress)
        let presenter = FeePresenter(service: interactor)

        return presenter
    }

}

extension FeeModule {

    enum FeeError: Error, LocalizedError {
        case insufficientAmountWithFeeBalance(coinValue: CoinValue)
        case insufficientFeeBalance(coinValue: CoinValue)
        case insufficientApproveFeeBalance(coinValue: CoinValue)

        var errorDescription: String? {
            switch self {
            case let .insufficientAmountWithFeeBalance(coinValue):
                return "swap.amount_error.insufficient_balance".localized(ValueFormatter.instance.format(coinValue: coinValue) ?? "")
            case let .insufficientFeeBalance(coinValue):
                return "swap.amount_error.insufficient_fee_alert".localized(coinValue.coin.title, ValueFormatter.instance.format(coinValue: coinValue) ?? "")
            case let .insufficientApproveFeeBalance(coinValue):
                return "swap.approve.insufficient_fee_alert".localized(coinValue.coin.title, ValueFormatter.instance.format(coinValue: coinValue) ?? "")
            }
        }
    }

}
