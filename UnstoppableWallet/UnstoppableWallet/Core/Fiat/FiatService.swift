import Foundation
import CurrencyKit
import RxSwift
import RxRelay
import MarketKit

class FiatService {
    private var disposeBag = DisposeBag()
    private var coinPriceDisposeBag = DisposeBag()
    private var queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.fiat-service", qos: .userInitiated)

    private let switchService: AmountTypeSwitchService
    private let currencyKit: CurrencyKit.Kit
    private let marketKit: MarketKit.Kit

    private(set) var token: Token?
    private var price: Decimal? {
        didSet {
            toggleAvailableRelay.accept(price != nil)
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

    private let amountAlreadyUpdatedRelay = PublishRelay<()>()

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
            price = coinPrice.value

            if coinAmountLocked {
                syncCurrencyAmount()
            } else {
                syncCurrencyAmount()
                syncCoinAmount()
            }
        } else {
            price = nil
        }

        sync()
    }

    private func sync(amountType: AmountTypeSwitchService.AmountType) {
        sync()
    }

    private func sync() {
        queue.async {
            if let token = self.token {
                let coinAmountInfo: AmountInfo = .coinValue(coinValue: CoinValue(kind: .token(token: token), value: self.coinAmount))
                let currencyAmountInfo: AmountInfo? = self.currencyAmount.map { .currencyValue(currencyValue: CurrencyValue(currency: self.currency, value: $0)) }

                switch self.switchService.amountType {
                case .coin:
                    self.primaryInfo = .amountInfo(amountInfo: coinAmountInfo)
                    self.secondaryAmountInfo = currencyAmountInfo
                case .currency:
                    self.primaryInfo = .amountInfo(amountInfo: currencyAmountInfo)
                    self.secondaryAmountInfo = coinAmountInfo
                }
            } else {
                self.primaryInfo = .amount(amount: self.coinAmount)
                self.secondaryAmountInfo = .currencyValue(currencyValue: .init(currency: self.currency, value: 0))
            }
        }
    }

    private func syncCoinAmount() {
        if let currencyAmount = currencyAmount, let price = price {
            coinAmount = price == 0 ? 0 : currencyAmount / price
        } else {
            coinAmount = 0
        }

        coinAmountRelay.accept(coinAmount)
    }

    private func syncCurrencyAmount() {
        if let price = price {
            currencyAmount = coinAmount * price
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

    var amountAlreadyUpdatedObservable: Observable<()> {
        amountAlreadyUpdatedRelay.asObservable()
    }

    var toggleAvailableObservable: Observable<Bool> {
        toggleAvailableRelay.asObservable()
    }

    func set(token: Token?) {
        self.token = token

        coinPriceDisposeBag = DisposeBag()

        if let token = token {
            sync(coinPrice: marketKit.coinPrice(coinUid: token.coin.uid, currencyCode: currency.code))

            if !token.isCustom {
                marketKit.coinPriceObservable(coinUid: token.coin.uid, currencyCode: currency.code)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
                        .subscribe(onNext: { [weak self] coinPrice in
                            self?.sync(coinPrice: coinPrice)
                        })
                        .disposed(by: coinPriceDisposeBag)
            }
        } else {
            price = nil
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
            amountAlreadyUpdatedRelay.accept(())
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
