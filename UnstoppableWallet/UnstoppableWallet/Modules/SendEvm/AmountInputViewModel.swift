import RxSwift
import RxCocoa
import CurrencyKit
import CoinKit

protocol IAmountInputService {
    var amount: Decimal { get }
    var coin: Coin? { get }
    var balance: Decimal? { get }

    var amountObservable: Observable<Decimal> { get }
    var coinObservable: Observable<Coin?> { get }

    func onChange(amount: Decimal)
}

class AmountInputViewModel {
    private static let maxCoinDecimal = 8

    private let disposeBag = DisposeBag()

    private let service: IAmountInputService
    private let fiatService: FiatService
    private let switchService: AmountTypeSwitchService
    private let decimalParser: IAmountDecimalParser
    private let isMaxSupported: Bool

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private var prefixRelay = BehaviorRelay<String?>(value: nil)
    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var isMaxEnabledRelay = BehaviorRelay<Bool>(value: false)
    private var secondaryTextRelay = BehaviorRelay<String?>(value: nil)
    private var switchEnabledRelay: BehaviorRelay<Bool>

    private var coinDecimal = AmountInputViewModel.maxCoinDecimal

    init(service: IAmountInputService, fiatService: FiatService, switchService: AmountTypeSwitchService, decimalParser: IAmountDecimalParser, isMaxSupported: Bool = true) {
        self.service = service
        self.fiatService = fiatService
        self.switchService = switchService
        self.decimalParser = decimalParser
        self.isMaxSupported = isMaxSupported
        switchEnabledRelay = BehaviorRelay(value: switchService.toggleAvailable)

        subscribe(disposeBag, service.amountObservable) { [weak self] in self?.sync(amount: $0) }
        subscribe(disposeBag, service.coinObservable) { [weak self] in self?.sync(coin: $0) }
        subscribe(disposeBag, fiatService.coinAmountObservable) { [weak self] in self?.syncCoin(amount: $0) }
        subscribe(disposeBag, fiatService.primaryInfoObservable) { [weak self] in self?.sync(primaryInfo: $0) }
        subscribe(disposeBag, fiatService.secondaryAmountInfoObservable) { [weak self] in self?.syncSecondary(amountInfo: $0) }
        subscribe(disposeBag, switchService.toggleAvailableObservable) { [weak self] in self?.switchEnabledRelay.accept($0) }

        sync(amount: service.amount)
        sync(coin: service.coin)
        syncCoin(amount: fiatService.coinAmount)
        sync(primaryInfo: fiatService.primaryInfo)
        syncSecondary(amountInfo: fiatService.secondaryAmountInfo)
    }

    private func sync(amount: Decimal) {
        fiatService.set(coinAmount: amount)
    }

    private func sync(coin: Coin?) {
        let max = AmountInputViewModel.maxCoinDecimal
        coinDecimal = min(max, (coin?.decimal ?? max))

        fiatService.set(coin: coin)

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
        default: return nil
        }
    }

    private func amountString(primaryInfo: FiatService.PrimaryInfo) -> String? {
        switch primaryInfo {
        case .amountInfo(let amountInfo):
            guard let amountInfo = amountInfo else {
                return nil
            }

            if amountInfo.value == 0 {
                return nil
            }

            decimalFormatter.maximumFractionDigits = min(amountInfo.decimal, Self.maxCoinDecimal)
            return decimalFormatter.string(from: amountInfo.value as NSNumber)
        case .amount(let amount):
            if amount == 0 {
                return nil
            }

            decimalFormatter.maximumFractionDigits = Self.maxCoinDecimal
            return decimalFormatter.string(from: amount as NSNumber)
        }
    }

    private func sync(primaryInfo: FiatService.PrimaryInfo) {
        amountRelay.accept(amountString(primaryInfo: primaryInfo))
        prefixRelay.accept(prefix(primaryInfo: primaryInfo))
    }

    private func syncSecondary(amountInfo: AmountInfo?) {
        secondaryTextRelay.accept(amountInfo?.formattedString)
    }

}

extension AmountInputViewModel {

    func isValid(amount: String?) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        switch switchService.amountType {
        case .coin: return amount.decimalCount <= coinDecimal
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

    var amountDriver: Driver<String?> {
        amountRelay.asDriver()
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

    func onChange(amount: String?) {
        let amount = decimalParser.parseAnyDecimal(from: amount) ?? 0

        fiatService.set(amount: amount)
    }

    func onTapMax() {
        guard let balance = service.balance else {
            return
        }

        fiatService.set(coinAmount: balance)
    }

    func onSwitch() {
        switchService.toggle()
    }

}
