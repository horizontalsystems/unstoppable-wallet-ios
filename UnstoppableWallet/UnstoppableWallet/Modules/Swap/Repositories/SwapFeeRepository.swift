import EthereumKit
import CurrencyKit
import UniswapKit
import RxSwift
import RxCocoa

class SwapFeeRepository {
    private let disposeBag = DisposeBag()
    private var feeDisposable: Disposable?

    private let uniswapKit: UniswapKit.Kit
    private let adapterManager: IAdapterManager
    private let provider: IFeeRateProvider
    private let rateManager: IRateManager
    private let baseCurrency: Currency

    private var feeCoin: Coin

    public let priority: FeeRatePriority

    init(uniswapKit: UniswapKit.Kit, adapterManager: IAdapterManager, provider: IFeeRateProvider, rateManager: IRateManager, baseCurrency: Currency, feeCoin: Coin) {
        self.uniswapKit = uniswapKit
        self.adapterManager = adapterManager
        self.provider = provider
        self.priority = provider.defaultFeeRatePriority
        self.rateManager = rateManager
        self.baseCurrency = baseCurrency
        self.feeCoin = feeCoin
    }

    private func currencyValue(coin: Coin, fee: Decimal) -> CurrencyValue? {
        let rate = nonExpiredRateValue(coinCode: coin.code, currencyCode: baseCurrency.code)

        return rate.map { CurrencyValue(currency: baseCurrency, value: $0 * fee) }
    }

    private func nonExpiredRateValue(coinCode: String, currencyCode: String) -> Decimal? {
        guard let marketInfo = rateManager.marketInfo(coinCode: coinCode, currencyCode: currencyCode), !marketInfo.expired else {
            return nil
        }
        return marketInfo.rate
    }

    private func handle(coin: Coin, gasLimit: Int, gasPrice: Int) throws -> SwapModule.SwapFeeInfo {
        guard  let erc20Adapter = adapterManager.adapter(for: coin) as? ISendEthereumAdapter else {
            throw AdapterError.unsupportedAccount
        }

        let fee = erc20Adapter.fee(gasPrice: gasPrice, gasLimit: gasLimit)
        let coinValue = CoinValue(coin: feeCoin, value: fee)

        guard erc20Adapter.ethereumBalance >= fee else {
            throw FeeModule.FeeError.insufficientFeeBalance(coinValue: coinValue)
        }

        return SwapModule.SwapFeeInfo(gasPrice: gasPrice,
                gasLimit: gasLimit,
                coinAmount: coinValue,
                currencyAmount: currencyValue(coin: feeCoin, fee: fee)
        )
    }

    private func handle(coin: Coin, gasPrice: Int, tradeData: TradeData) -> Single<SwapModule.SwapFeeInfo> {
        Single.error(AppError.unknownError)
//        uniswapKit.estimateSwapSingle(tradeData: tradeData, gasPrice: gasPrice)
//                .flatMap { gasLimit in
//                    do {
//                        let info = try self.handle(coin: coin, gasLimit: gasLimit, gasPrice: gasPrice)
//                        return Single.just(info)
//                    } catch {
//                        return Single.error(error)
//                    }
//                }
    }

    public func swapFeeInfo(coin: Coin, tradeData: TradeData) -> Single<SwapModule.SwapFeeInfo> {
        let priority = self.priority
        return provider.feeRate
                .flatMap { rate in
                    let gasPrice = rate.feeRate(priority: priority)
                    return self.handle(coin: coin, gasPrice: gasPrice, tradeData: tradeData)
                }
    }

}
