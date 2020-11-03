import EthereumKit
import RxSwift
import RxCocoa
import CurrencyKit

class FeeService {
    private let disposeBag = DisposeBag()

    private let erc20Adapter: IErc20Adapter
    private let provider: IFeeRateProvider
    private let rateManager: IRateManager
    private let baseCurrency: Currency

    private var feeCoin: Coin
    private var amount: Decimal
    private var spenderAddress: Address

    public let priority: FeeRatePriority
    public var gasPrice: Int? = nil
    public var gasLimit: Int? = nil

    private let feeRelay = BehaviorRelay<DataStatus<(coinValue: CoinValue, currencyValue: CurrencyValue?)>>(value: .loading)

    init(adapter: IErc20Adapter, provider: IFeeRateProvider, rateManager: IRateManager, baseCurrency: Currency, feeCoin: Coin, amount: Decimal, spenderAddress: Address) {
        self.erc20Adapter = adapter
        self.provider = provider
        self.priority = provider.defaultFeeRatePriority
        self.rateManager = rateManager
        self.baseCurrency = baseCurrency
        self.feeCoin = feeCoin
        self.amount = amount
        self.spenderAddress = spenderAddress

        fetchFeeRate()
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

    private func handle(gasLimit: Int) {
        self.gasLimit = gasLimit

        guard let gasPrice = gasPrice else {
            return
        }

        let fee = erc20Adapter.fee(gasPrice: gasPrice, gasLimit: gasLimit)
        let coinValue = CoinValue(coin: feeCoin, value: fee)

        guard erc20Adapter.ethereumBalance >= fee else {
            feeRelay.accept(.failed(FeeModule.FeeError.insufficientFeeBalance(coinValue: coinValue)))
            return
        }

        let feeValues = (
                coinValue: coinValue,
                currencyValue: currencyValue(coin: feeCoin, fee: fee)
        )

        feeRelay.accept(.completed(feeValues))
    }

    private func handle(feeRate: FeeRate) {
        gasPrice = feeRate.feeRate(priority: priority)
//
//        return erc20Adapter.estimateApproveSingle(spenderAddress: spenderAddress, amount: amount, gasPrice: feeRate.feeRate(priority: priority))
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
//                .observeOn(MainScheduler.instance)
//                .subscribe(onSuccess: { [weak self] gasLimit in
//                    self?.handle(gasLimit: gasLimit)
//                }, onError: { [weak self] error in
//                    self?.feeRelay.accept(.failed(error))
//                })
//                .disposed(by: disposeBag)
    }

    private func fetchFeeRate() {
        feeRelay.accept(.loading)

        provider.feeRate
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] feeRate in
                    self?.handle(feeRate: feeRate)
                }, onError: { [weak self] error in
                    self?.feeRelay.accept(.failed(error))
                })
                .disposed(by: disposeBag)
    }

    var feeState: Observable<DataStatus<(coinValue: CoinValue, currencyValue: CurrencyValue?)>> {
        feeRelay.asObservable()
    }

}
