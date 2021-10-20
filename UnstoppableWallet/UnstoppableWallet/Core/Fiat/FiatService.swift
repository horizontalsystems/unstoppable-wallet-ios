import CurrencyKit
import RxSwift
import RxRelay
import XRatesKit
import MarketKit

class FiatService {
    private var disposeBag = DisposeBag()
    private var coinPriceDisposeBag = DisposeBag()

    private let switchService: AmountTypeSwitchService
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit

    private var platformCoin: PlatformCoin?
    private var rate: Decimal? {
        didSet {
            toggleAvailableRelay.accept(rate != nil)
        }
    }

    private let coinAmountRelay = PublishRelay<Decimal>()
    private(set) var coinAmount: Decimal = 0

    private var currencyAmount: Decimal?

    private let primaryInfoRelay = PublishRelay<PrimaryInfo>()
    private(set) var primaryInfo: PrimaryInfo = .amount(amount: 0) {
        didSet {
            primaryInfoRelay.accept(primaryInfo)
        }
    }

    private let secondaryAmountInfoRelay = PublishRelay<AmountInfo?>()
    private(set) var secondaryAmountInfo: AmountInfo? {
        didSet {
            secondaryAmountInfoRelay.accept(secondaryAmountInfo)
        }
    }

    private var toggleAvailableRelay = BehaviorRelay<Bool>(value: false)

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coinAmountLocked = false

    init(switchService: AmountTypeSwitchService, currencyKit: CurrencyKit.Kit, marketKit: MarketKit.Kit) {
        self.switchService = switchService
        self.currencyKit = currencyKit
        self.marketKit = marketKit

        subscribe(disposeBag, switchService.amountTypeObservable) { [weak self] in self?.sync(amountType: $0) }

        sync()
    }

    private func sync(coinPrice: CoinPrice?) {
        if let coinPrice = coinPrice, !coinPrice.expired {
            rate = coinPrice.value

            if coinAmountLocked {
                syncCurrencyAmount()
            } else {
                switch switchService.amountType {
                case .coin:
                    syncCurrencyAmount()
                case .currency:
                    syncCoinAmount()
                }
            }
        } else {
            rate = nil
        }

        sync()
    }

    private func sync(amountType: AmountTypeSwitchService.AmountType) {
        sync()
    }

    private func sync() {
        if let platformCoin = platformCoin {
            let coinAmountInfo: AmountInfo = .coinValue(coinValue: CoinValue(kind: .platformCoin(platformCoin: platformCoin), value: coinAmount))
            let currencyAmountInfo: AmountInfo? = currencyAmount.map { .currencyValue(currencyValue: CurrencyValue(currency: currency, value: $0)) }

            switch switchService.amountType {
            case .coin:
                primaryInfo = .amountInfo(amountInfo: coinAmountInfo)
                secondaryAmountInfo = currencyAmountInfo
            case .currency:
                primaryInfo = .amountInfo(amountInfo: currencyAmountInfo)
                secondaryAmountInfo = coinAmountInfo
            }
        } else {
            primaryInfo = .amount(amount: coinAmount)
            secondaryAmountInfo = .currencyValue(currencyValue: .init(currency: currency, value: 0))
        }
    }

    private func syncCoinAmount() {
        if let currencyAmount = currencyAmount, let rate = rate {
            coinAmount = rate == 0 ? 0 : currencyAmount / rate
        } else {
            coinAmount = 0
        }

        coinAmountRelay.accept(coinAmount)
    }

    private func syncCurrencyAmount() {
        if let rate = rate {
            currencyAmount = coinAmount * rate
        } else {
            currencyAmount = nil
        }
    }

}

extension FiatService {

    var coinAmountObservable: Observable<Decimal> {
        coinAmountRelay.asObservable()
    }

    var primaryInfoObservable: Observable<PrimaryInfo> {
        primaryInfoRelay.asObservable()
    }

    var secondaryAmountInfoObservable: Observable<AmountInfo?> {
        secondaryAmountInfoRelay.asObservable()
    }

    var toggleAvailableObservable: Observable<Bool> {
        toggleAvailableRelay.asObservable()
    }

    func set(platformCoin: PlatformCoin?) {
        self.platformCoin = platformCoin

        coinPriceDisposeBag = DisposeBag()

        if let platformCoin = platformCoin {
            sync(coinPrice: marketKit.coinPrice(coinUid: platformCoin.coin.uid, currencyCode: currency.code))

            marketKit.coinPriceObservable(coinUid: platformCoin.coin.uid, currencyCode: currency.code)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                    .subscribe(onNext: { [weak self] coinPrice in
                        self?.sync(coinPrice: coinPrice)
                    })
                    .disposed(by: coinPriceDisposeBag)
        } else {
            rate = nil
            currencyAmount = nil
            sync()
        }
    }

    func set(amount: Decimal) {
        switch switchService.amountType {
        case .coin:
            coinAmount = amount
            coinAmountRelay.accept(coinAmount)
            syncCurrencyAmount()
        case .currency:
            currencyAmount = amount
            syncCoinAmount()
        }

        sync()
    }

    func set(coinAmount: Decimal, notify: Bool = false) {
        guard self.coinAmount != coinAmount else {
            return
        }

        self.coinAmount = coinAmount

        if notify {
            coinAmountRelay.accept(coinAmount)
        }

        syncCurrencyAmount()
        sync()
    }

}

extension FiatService {

    enum PrimaryInfo {
        case amountInfo(amountInfo: AmountInfo?)
        case amount(amount: Decimal)
    }

}
