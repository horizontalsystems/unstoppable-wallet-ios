import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift

class FiatService {
    private var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var queue = DispatchQueue(label: "\(AppConfig.label).fiat-service", qos: .userInitiated)

    private let switchService: AmountTypeSwitchService
    private let currencyManager: CurrencyManager
    private let marketKit: MarketKit.Kit

    private var appValueKind: AppValue.Kind?
    var token: Token? { appValueKind?.token }

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

    private let amountAlreadyUpdatedRelay = PublishRelay<Void>()

    private var toggleAvailableRelay = BehaviorRelay<Bool>(value: false)

    var currency: Currency {
        currencyManager.baseCurrency
    }

    var coinAmountLocked = false

    init(switchService: AmountTypeSwitchService, currencyManager: CurrencyManager, marketKit: MarketKit.Kit, amount: Decimal = 0) {
        self.switchService = switchService
        self.currencyManager = currencyManager
        self.marketKit = marketKit
        coinAmount = amount

        subscribe(disposeBag, switchService.amountTypeObservable) { [weak self] in self?.sync(amountType: $0) }

        sync()
    }

    private func sync(coinPrice: CoinPrice?) {
        if let coinPrice, !coinPrice.expired {
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

    private func sync(amountType _: AmountTypeSwitchService.AmountType) {
        sync()
    }

    private func sync() {
        queue.async {
            if let appValueKind = self.appValueKind {
                let coinAmountInfo: AmountInfo = .appValue(appValue: AppValue(kind: appValueKind, value: self.coinAmount))
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
                self.secondaryAmountInfo = nil
            }
        }
    }

    private func syncCoinAmount() {
        if let currencyAmount, let price {
            coinAmount = price == 0 ? 0 : currencyAmount / price
        } else {
            coinAmount = 0
        }

        coinAmountRelay.accept(coinAmount)
    }

    private func syncCurrencyAmount() {
        if let price {
            currencyAmount = coinAmount * price
        } else {
            currencyAmount = nil
        }
    }

    private func fetchRate(coin: Coin, subscribe: Bool) {
        sync(coinPrice: marketKit.coinPrice(coinUid: coin.uid, currencyCode: currency.code))

        if subscribe {
            marketKit.coinPricePublisher(coinUid: coin.uid, currencyCode: currency.code)
                .sink { [weak self] coinPrice in
                    self?.sync(coinPrice: coinPrice)
                }
                .store(in: &cancellables)
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

    var amountAlreadyUpdatedObservable: Observable<Void> {
        amountAlreadyUpdatedRelay.asObservable()
    }

    var toggleAvailableObservable: Observable<Bool> {
        toggleAvailableRelay.asObservable()
    }

    func set(token: Token?) {
        set(appValueKind: token.flatMap { .token(token: $0) })
    }

    func set(appValueKind: AppValue.Kind?) {
        self.appValueKind = appValueKind

        cancellables = Set()
        var fetching = true

        if let appValueKind {
            switch appValueKind {
            case let .token(token):
                fetchRate(coin: token.coin, subscribe: !token.isCustom)
            default:
                if let coin = appValueKind.coin {
                    fetchRate(coin: coin, subscribe: false)
                } else {
                    fetching = false
                }
            }
        } else {
            fetching = false
        }

        if !fetching {
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
