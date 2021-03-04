import RxSwift
import RxCocoa
import CurrencyKit
import CoinKit

protocol IAmountInputService {
    var amount: Decimal? { get }
    var coin: Coin? { get }

    var amountObservable: Observable<Decimal?> { get }
    var coinObservable: Observable<Coin?> { get }

    func onChange(amount: Decimal?)
}

class AmountInputViewModel {
    private static let maxValidDecimals = 8

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
    private var switchEnabledRelay = BehaviorRelay<Bool>(value: true)

    private var validDecimals = AmountInputViewModel.maxValidDecimals

    init(service: IAmountInputService, fiatService: FiatService, switchService: AmountTypeSwitchService, decimalParser: IAmountDecimalParser, isMaxSupported: Bool = true) {
        self.service = service
        self.fiatService = fiatService
        self.switchService = switchService
        self.decimalParser = decimalParser
        self.isMaxSupported = isMaxSupported

        subscribe(disposeBag, service.amountObservable) { [weak self] in self?.sync(amount: $0) }
        subscribe(disposeBag, service.coinObservable) { [weak self] in self?.sync(coin: $0) }
        subscribe(disposeBag, fiatService.fullAmountDataObservable) { [weak self] in self?.sync(fullAmountInfo: $0, force: false) }
//        subscribe(disposeBag, switchService.toggleAvailableObservable) { [weak self] in self?.switchEnabledRelay.accept($0) }

        sync(amount: service.amount)
        sync(coin: service.coin)
        sync(fullAmountInfo: nil, force: false)
    }

    private func sync(amount: Decimal?) {
//        if coinCardService.isEstimated {
//            let fullAmountInfo = fiatService.buildForCoin(amount: amount)
//            sync(fullAmountInfo: fullAmountInfo, force: false)
//        }
    }

    private func sync(coin: Coin?) {
        let max = AmountInputViewModel.maxValidDecimals
        validDecimals = min(max, (coin?.decimal ?? max))

        fiatService.set(coin: coin)
    }

    private var secondaryPlaceholder: String? {
        switch switchService.amountType {
        case .coin:
            let amountInfo = AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: fiatService.currency, value: 0))
            return amountInfo.formattedString
        case .currency:
            let amountInfo = service.coin.map { AmountInfo.coinValue(coinValue: CoinValue(coin: $0, value: 0)) }
            return amountInfo?.formattedString
        }
    }

    private func sync(fullAmountInfo: FiatService.FullAmountInfo?, force: Bool = false, inputAmount: Decimal? = nil) {
        prefixRelay.accept(switchService.amountType == .currency ? fiatService.currency.symbol : nil)

        guard let fullAmountInfo = fullAmountInfo else {
//            if !force && coinCardService.isEstimated {
                amountRelay.accept(nil)
//            }

            secondaryTextRelay.accept(secondaryPlaceholder)

            setCoinValueToService(coinValue: inputAmount, force: force)
            return
        }

        decimalFormatter.maximumFractionDigits = min(fullAmountInfo.primaryDecimal, Self.maxValidDecimals)
        let amountString = decimalFormatter.string(from: fullAmountInfo.primaryValue as NSNumber)

        amountRelay.accept(amountString)
        secondaryTextRelay.accept(fullAmountInfo.secondaryInfo?.formattedString)

        setCoinValueToService(coinValue: fullAmountInfo.coinValue.value, force: force)
    }

    private func setCoinValueToService(coinValue: Decimal?, force: Bool) {
//        if force || !coinCardService.isEstimated {
            service.onChange(amount: coinValue)
//        }
    }

}

extension AmountInputViewModel {

    func isValid(amount: String?) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        return amount.decimalCount <= validDecimals
    }

    func equalValue(lhs: String?, rhs: String?) -> Bool {
        guard let lhsString = lhs, let rhsString = rhs else {
            return lhs == rhs
        }
        guard let lhsDecimal = decimalParser.parseAnyDecimal(from: lhsString),
              let rhsDecimal = decimalParser.parseAnyDecimal(from: rhsString) else {
            return false
        }

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

    func onChange(amount: String?) {                     // Force change from inputView
        let amount = decimalParser.parseAnyDecimal(from: amount)

        let fullAmountInfo = fiatService.buildAmountInfo(amount: amount)
        sync(fullAmountInfo: fullAmountInfo, force: true, inputAmount: amount)
    }

    func onTapMax() {
//        guard let balance = coinCardService.balance else {
//            return
//        }
//
//        let fullAmountInfo = fiatService.buildForCoin(amount: balance)
//        sync(fullAmountInfo: fullAmountInfo, force: true, inputAmount: balance)
    }

    func onSwitch() {
        switchService.toggle()
    }

}
