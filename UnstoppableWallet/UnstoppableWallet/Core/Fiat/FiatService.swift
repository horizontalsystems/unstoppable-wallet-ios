import CurrencyKit
import RxSwift
import RxRelay
import XRatesKit

struct FullAmountInfo {
    let primaryInfo: AmountInfo
    let secondaryInfo: AmountInfo?
    let coinValue: CoinValue

    var primaryValue: Decimal {
        switch primaryInfo {
        case .currencyValue(let currency): return currency.value
        case .coinValue(let coin): return coin.value
        }
    }

    var primaryDecimal: Int {
        switch primaryInfo {
        case .currencyValue(let currency): return currency.currency.decimal
        case .coinValue(let coin): return coin.coin.decimal
        }
    }

}

class FiatService {
    private var disposeBag = DisposeBag()
    private var marketInfoDisposeBag = DisposeBag()

    private let switchService: AmountTypeSwitchService
    private let currencyKit: ICurrencyKit
    private let rateManager: IRateManager

    private var coin: Coin?
    private var coinAmount: Decimal?
    private var currencyAmount: Decimal?

    var toggleAvailableRelay = PublishRelay<Bool>()
    var toggleAvailable = false {
        didSet {
            toggleAvailableRelay.accept(toggleAvailable)
        }
    }

    private var marketInfo: MarketInfo?
    private var rate: Decimal? {
        guard let marketInfo = marketInfo, !marketInfo.expired else {
            return nil
        }
        return marketInfo.rate
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    private let fullAmountInfoRelay = PublishRelay<FullAmountInfo?>()
    private var fullAmountInfo: FullAmountInfo?

    init(switchService: AmountTypeSwitchService, currencyKit: ICurrencyKit, rateManager: IRateManager) {
        self.switchService = switchService
        self.currencyKit = currencyKit
        self.rateManager = rateManager

        subscribe(disposeBag, switchService.amountTypeObservable) { [weak self] in self?.sync(amountType: $0) }
    }

    func subscribeToMarketInfo() {
        marketInfoDisposeBag = DisposeBag()
        toggleAvailable = false

        guard let coin = coin else {
            return
        }

        sync(marketInfo: rateManager.marketInfo(coinCode: coin.code, currencyCode: currency.code))
        rateManager.marketInfoObservable(coinCode: coin.code, currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                .subscribe(onNext: { [weak self] marketInfo in
                    self?.sync(marketInfo: marketInfo)
                })
                .disposed(by: marketInfoDisposeBag)
    }

    private func sync(marketInfo: MarketInfo?) {
        self.marketInfo = marketInfo
        toggleAvailable = rate != nil

        syncFullData()
        fullAmountInfoRelay.accept(fullAmountInfo)
    }

    private func sync(amountType: AmountType) {
        syncFullData()
        fullAmountInfoRelay.accept(fullAmountInfo)
    }

    private func syncFullData() {
        guard let coin = coin,
              let coinAmount = coinAmount else {

            fullAmountInfo = nil
            return
        }

        switch switchService.amountType {
        case .coin:
            let primary = CoinValue(coin: coin, value: coinAmount)
            let secondary = currencyAmount.map { CurrencyValue(currency: currency, value: $0) }

            fullAmountInfo = FullAmountInfo(
                            primaryInfo: .coinValue(coinValue: primary),
                            secondaryInfo: secondary.map { .currencyValue(currencyValue: $0) },
                            coinValue: primary
                    )
        case .currency:
            guard let currencyAmount = currencyAmount else {
                fullAmountInfo = nil
                return
            }

            let primary = CurrencyValue(currency: currency, value: currencyAmount)
            let secondary = CoinValue(coin: coin, value: coinAmount)

            fullAmountInfo = FullAmountInfo(
                            primaryInfo: .currencyValue(currencyValue: primary),
                            secondaryInfo: .coinValue(coinValue: secondary),
                            coinValue: secondary
            )
        }
    }

}

extension FiatService {

    func buildForCoin(amount: Decimal?) -> FullAmountInfo? {
        coinAmount = amount

        currencyAmount = amount.flatMap { coinAmount in
            guard let rate = rate else {
                return nil
            }
            return coinAmount * rate
        }

        syncFullData()
        return fullAmountInfo
    }

    func buildForCurrency(amount: Decimal?) -> FullAmountInfo? {
        currencyAmount = amount

        coinAmount = amount.flatMap { currencyAmount in
            guard let rate = rate else {
                return nil
            }

            return rate == 0 ? 0 : currencyAmount / rate
        }

        syncFullData()
        return fullAmountInfo
    }

    func buildAmountInfo(amount: Decimal?) -> FullAmountInfo? {                        // Force change from inputView
        switch switchService.amountType {
        case .coin: return buildForCoin(amount: amount)
        case .currency: return buildForCurrency(amount: amount)
        }
    }

    func set(coin: Coin?) {
        self.coin = coin

        marketInfo = nil
        subscribeToMarketInfo()

        switch switchService.amountType {
        case .coin: fullAmountInfoRelay.accept(buildForCoin(amount: coinAmount))
        case .currency: fullAmountInfoRelay.accept(buildForCurrency(amount: currencyAmount))
        }
    }

    var fullAmountDataObservable: Observable<FullAmountInfo?> {
        fullAmountInfoRelay.asObservable()
    }

}

extension FiatService: IToggleAvailableDelegate {

    var toggleAvailableObservable: Observable<Bool> {
        toggleAvailableRelay.asObservable()
    }

}
