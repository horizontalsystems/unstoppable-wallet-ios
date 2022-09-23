import Foundation
import RxSwift
import RxCocoa
import CurrencyKit
import MarketKit

protocol IAmountInputService {
    var amount: Decimal { get }
    var token: Token? { get }
    var balance: Decimal? { get }

    var amountObservable: Observable<Decimal> { get }
    var tokenObservable: Observable<Token?> { get }
    var balanceObservable: Observable<Decimal?> { get }
    var amountWarningObservable: Observable<AmountInputViewModel.AmountWarning?> { get }

    func onChange(amount: Decimal)
}

extension IAmountInputService {

    var amountWarningObservable: Observable<AmountInputViewModel.AmountWarning?> {
        Observable.just(nil)
    }

}

class AmountInputViewModel {
    private var queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.fiat-service", qos: .userInitiated)

    private static let fallbackCoinDecimals = 8

    private let disposeBag = DisposeBag()

    private let service: IAmountInputService
    private let fiatService: FiatService
    private let switchService: AmountTypeSwitchService
    private let decimalParser: AmountDecimalParser
    private let isMaxSupported: Bool

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    private var prefixRelay = BehaviorRelay<String?>(value: nil)
    private var prefixTypeRelay = BehaviorRelay<InputType>(value: .coin)
    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var amountTypeRelay = BehaviorRelay<InputType>(value: .coin)
    private var isMaxEnabledRelay = BehaviorRelay<Bool>(value: false)
    private var secondaryTextRelay = BehaviorRelay<String?>(value: nil)
    private var secondaryTextTypeRelay = BehaviorRelay<InputType>(value: .currency)
    private var switchEnabledRelay: BehaviorRelay<Bool>
    private var amountWarningRelay = BehaviorRelay<String?>(value: nil)

    private var coinDecimals: Int
    let publishAmountRelay = PublishRelay<Decimal>()

    init(service: IAmountInputService, fiatService: FiatService, switchService: AmountTypeSwitchService, decimalParser: AmountDecimalParser, coinDecimals: Int = AmountInputViewModel.fallbackCoinDecimals, isMaxSupported: Bool = true) {
        self.service = service
        self.fiatService = fiatService
        self.switchService = switchService
        self.decimalParser = decimalParser
        self.coinDecimals = coinDecimals
        self.isMaxSupported = isMaxSupported
        switchEnabledRelay = BehaviorRelay(value: switchService.toggleAvailable)

        subscribe(disposeBag, service.amountObservable) { [weak self] in self?.sync(amount: $0) }
        subscribe(disposeBag, service.balanceObservable) { [weak self] in self?.sync(balance: $0) }
        subscribe(disposeBag, service.amountWarningObservable) { [weak self] in self?.sync(amountWarning: $0) }
        subscribe(disposeBag, service.tokenObservable) { [weak self] in self?.sync(token: $0) }
        subscribe(disposeBag, fiatService.coinAmountObservable) { [weak self] in self?.syncCoin(amount: $0) }
        subscribe(disposeBag, fiatService.primaryInfoObservable) { [weak self] in self?.sync(primaryInfo: $0) }
        subscribe(disposeBag, fiatService.secondaryAmountInfoObservable) { [weak self] in self?.syncSecondary(amountInfo: $0) }
        subscribe(disposeBag, switchService.toggleAvailableObservable) { [weak self] in self?.switchEnabledRelay.accept($0) }
        subscribe(disposeBag, publishAmountRelay.asObservable()) { [weak self] in self?.fiatService.set(coinAmount: $0, notify: true) }

        sync(amount: service.amount)
        sync(token: service.token)
    }

    private func sync(amountWarning: AmountWarning?) {
        amountWarningRelay.accept(amountWarning.flatMap { warning in
            switch warning {
            case .highPriceImpact(let priceImpact): return "-\(priceImpact.description)%"
            }
        })
    }

    private func sync(amount: Decimal) {
        queue.async { [weak self] in
            self?.fiatService.set(coinAmount: amount)
        }
    }

    private func sync(balance: Decimal?) {
        queue.async { [weak self] in
            self?.updateMaxEnabled()
        }
    }

    private func sync(token: Token?) {
        queue.async { [weak self] in
            self?.coinDecimals = token?.decimals ?? AmountInputViewModel.fallbackCoinDecimals

            self?.fiatService.set(token: token)
            self?.updateMaxEnabled()
        }
    }

    private func updateMaxEnabled() {
        isMaxEnabledRelay.accept(isMaxSupported && (service.balance ?? 0) > 0)
    }

    private func syncCoin(amount: Decimal) {
        service.onChange(amount: amount)
    }

    private func prefix(primaryInfo: FiatService.PrimaryInfo) -> String? {
        switch primaryInfo {
        case .amountInfo(let amountInfo):
            guard let amountInfo = amountInfo else {
                return nil
            }

            switch amountInfo {
            case .currencyValue(let currencyValue): return currencyValue.currency.symbol
            default: return nil
            }
        default:
            prefixTypeRelay.accept(.coin)

            return nil
        }
    }

    private func amountString(primaryInfo: FiatService.PrimaryInfo) -> String? {
        switch primaryInfo {
        case .amountInfo(let amountInfo):
            amountTypeRelay.accept(InputType.inputType(amountInfo: amountInfo))

            guard let amountInfo = amountInfo else {
                return nil
            }

            if amountInfo.value == 0 {
                return nil
            }

            decimalFormatter.maximumSignificantDigits = amountInfo.value.significandDigits(fractionDigits: amountInfo.decimal)
            return decimalFormatter.string(from: amountInfo.value as NSDecimalNumber)
        case .amount(let amount):
            amountTypeRelay.accept(.coin)

            if amount == 0 {
                return nil
            }

            decimalFormatter.maximumSignificantDigits = amount.significandDigits(fractionDigits: Self.fallbackCoinDecimals)
            return decimalFormatter.string(from: amount as NSDecimalNumber)
        }
    }

    private func sync(primaryInfo: FiatService.PrimaryInfo) {
        switch primaryInfo {
        case .amountInfo(let amountInfo):
            amountTypeRelay.accept(InputType.inputType(amountInfo: amountInfo))
            prefixTypeRelay.accept(InputType.inputType(amountInfo: amountInfo))
        case .amount:
            amountTypeRelay.accept(.coin)
            prefixTypeRelay.accept(.coin)
        }

        amountRelay.accept(amountString(primaryInfo: primaryInfo))
        prefixRelay.accept(prefix(primaryInfo: primaryInfo))
    }

    private func syncSecondary(amountInfo: AmountInfo?) {
        secondaryTextTypeRelay.accept(InputType.inputType(amountInfo: amountInfo))
        secondaryTextRelay.accept(amountInfo?.formattedFull)
    }

}

extension AmountInputViewModel {

    func isValid(amount: String?) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        switch switchService.amountType {
        case .coin: return amount.decimalCount <= coinDecimals
        case .currency: return amount.decimalCount <= fiatService.currency.decimal
        }
    }

    func equalValue(lhs: String?, rhs: String?) -> Bool {
        let lhsDecimal = decimalParser.parseAnyDecimal(from: lhs) ?? 0
        let rhsDecimal = decimalParser.parseAnyDecimal(from: rhs) ?? 0

        return lhsDecimal == rhsDecimal
    }

    var prefixDriver: Driver<String?> {
        prefixRelay.asDriver()
    }

    var prefixTypeDriver: Driver<InputType> {
        prefixTypeRelay.distinctUntilChanged().asDriver(onErrorJustReturn: .coin)
    }

    var amountDriver: Driver<String?> {
        amountRelay.asDriver()
    }

    var amountTypeDriver: Driver<InputType> {
        amountTypeRelay.distinctUntilChanged().asDriver(onErrorJustReturn: .coin)
    }

    var isMaxEnabledDriver: Driver<Bool> {
        isMaxEnabledRelay.asDriver()
    }

    var switchEnabledDriver: Driver<Bool> {
        switchEnabledRelay.asDriver()
    }

    var secondaryTextDriver: Driver<String?> {
        secondaryTextRelay.asDriver()
    }

    var secondaryTextTypeDriver: Driver<InputType> {
        secondaryTextTypeRelay.distinctUntilChanged().asDriver(onErrorJustReturn: .coin)
    }

    var amountWarningDriver: Driver<String?> {
        amountWarningRelay.asDriver()
    }

    func onChange(amount: String?) {
        let amount = decimalParser.parseAnyDecimal(from: amount) ?? 0

        fiatService.set(amount: amount)
    }

    func onTapMax() {
        guard let balance = service.balance else {
            return
        }

        fiatService.set(coinAmount: balance, notify: true)
    }

    func onSwitch() {
        switchService.toggle()
    }

}

extension AmountInputViewModel {

    enum InputType {
        case coin
        case currency

        static func inputType(amountInfo: AmountInfo?) -> Self {
            switch amountInfo {
            case .currencyValue: return .currency
            default: return .coin
            }
        }
    }

    enum AmountWarning {
        case highPriceImpact(priceImpact: Decimal)
    }

}

extension AmountInputViewModel: IAmountPublishService {}
