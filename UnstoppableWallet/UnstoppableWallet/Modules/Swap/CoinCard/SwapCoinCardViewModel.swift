import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit

enum SecondaryInfoType {
    case placeholder
    case value
}

struct SecondaryInfoViewItem {
    let text: String?
    let type: SecondaryInfoType
}

class SwapCoinCardViewModel {
    private static let maxValidDecimals = 8

    let disposeBag = DisposeBag()

    private let coinCardService: ISwapCoinCardService
    private let fiatService: FiatService
    private let switchService: AmountTypeSwitchService

    let decimalParser: IAmountDecimalParser

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    private var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var prefixRelay = BehaviorRelay<String?>(value: nil)
    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var secondaryInfoRelay = BehaviorRelay<SecondaryInfoViewItem?>(value: nil)
    private var balanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Bool>(value: false)
    private var tokenCodeRelay = BehaviorRelay<String?>(value: nil)
    private var switchEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var validDecimals = SwapCoinCardViewModel.maxValidDecimals

    init(coinCardService: ISwapCoinCardService, fiatService: FiatService, switchService: AmountTypeSwitchService, decimalParser: IAmountDecimalParser) {
        self.coinCardService = coinCardService
        self.fiatService = fiatService
        self.switchService = switchService
        self.decimalParser = decimalParser

        subscribeToService()
    }

    func subscribeToService() {
        sync(estimated: coinCardService.isEstimated)
        sync(amount: coinCardService.amount)
        sync(coin: coinCardService.coin)
        sync(balance: coinCardService.balance)
        sync(fullAmountInfo: nil, force: false)

        subscribe(disposeBag, coinCardService.isEstimatedObservable) { [weak self] in self?.sync(estimated: $0) }
        subscribe(disposeBag, coinCardService.amountObservable) { [weak self] in self?.sync(amount: $0) }
        subscribe(disposeBag, coinCardService.coinObservable) { [weak self] in self?.sync(coin: $0) }
        subscribe(disposeBag, coinCardService.balanceObservable) { [weak self] in self?.sync(balance: $0) }
        subscribe(disposeBag, coinCardService.errorObservable) { [weak self] in self?.sync(error: $0) }
        subscribe(disposeBag, fiatService.fullAmountDataObservable) { [weak self] in self?.sync(fullAmountInfo: $0, force: false) }
        subscribe(disposeBag, switchService.toggleAvailableObservable) { [weak self] in self?.switchEnabledRelay.accept($0) }
    }

    private func sync(estimated: Bool) {
        isEstimatedRelay.accept(estimated)
    }

    private func sync(amount: Decimal?) {
        if coinCardService.isEstimated {
            let fullAmountInfo = fiatService.buildForCoin(amount: amount)
            sync(fullAmountInfo: fullAmountInfo, force: false)
        }
    }

    private func sync(coin: Coin?) {
        let max = SwapCoinCardViewModel.maxValidDecimals
        validDecimals = min(max, (coin?.decimal ?? max))

        fiatService.set(coin: coin)
        tokenCodeRelay.accept(coin?.code)
    }

    private func sync(balance: Decimal?) {
        guard let coin = coinCardService.coin else {
            balanceRelay.accept(nil)
            return
        }

        guard let balance = balance else {
            balanceRelay.accept("n/a".localized)
            return
        }

        let coinValue = CoinValue(coin: coin, value: balance)
        balanceRelay.accept(ValueFormatter.instance.format(coinValue: coinValue))
    }

    private func sync(error: Error?) {
        balanceErrorRelay.accept(error != nil)
    }

    private var secondaryPlaceholder: SecondaryInfoViewItem {
        switch switchService.amountType {
        case .coin:
            let amountInfo = AmountInfo.currencyValue(currencyValue: CurrencyValue(currency: fiatService.currency, value: 0))
            return SecondaryInfoViewItem(text: amountInfo.formattedString, type: .placeholder)
        case .currency:
            let amountInfo = coinCardService.coin.map { AmountInfo.coinValue(coinValue: CoinValue(coin: $0, value: 0)) }
            return SecondaryInfoViewItem(text: amountInfo?.formattedString, type: .placeholder)
        }
    }

    private func sync(fullAmountInfo: FullAmountInfo?, force: Bool = false, inputAmount: Decimal? = nil) {
        prefixRelay.accept(switchService.amountType == .currency ? fiatService.currency.symbol : nil)

        guard let fullAmountInfo = fullAmountInfo else {
            if !force {
                amountRelay.accept(nil)
            }

            secondaryInfoRelay.accept(secondaryPlaceholder)

            setCoinValueToService(coinValue: inputAmount, force: force)
            return
        }

        decimalFormatter.maximumFractionDigits = min(fullAmountInfo.primaryDecimal, Self.maxValidDecimals)
        let amountString = decimalFormatter.string(from: fullAmountInfo.primaryValue as NSNumber)

        amountRelay.accept(amountString)
        secondaryInfoRelay.accept(SecondaryInfoViewItem(text:fullAmountInfo.secondaryInfo?.formattedString, type: .value))

        setCoinValueToService(coinValue: fullAmountInfo.coinValue.value, force: force)
    }

    private func setCoinValueToService(coinValue: Decimal?, force: Bool) {
        if force || !coinCardService.isEstimated {
            coinCardService.onChange(amount: coinValue)
        }
    }

    func onChange(amount: String?) {                     // Force change from inputView
        let amount = decimalParser.parseAnyDecimal(from: amount)

        let fullAmountInfo = fiatService.buildAmountInfo(amount: amount)
        sync(fullAmountInfo: fullAmountInfo, force: true, inputAmount: amount)
    }

    func onSelect(coin: Coin) {
        coinCardService.onChange(coin: coin)
        fiatService.set(coin: coin)
    }

    func onSwitch() {
        switchService.toggle()
    }

}

extension SwapCoinCardViewModel {

    var isEstimated: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

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

    var switchEnabledDriver: Driver<Bool> {
        switchEnabledRelay.asDriver()
    }

    var secondaryInfoDriver: Driver<SecondaryInfoViewItem?> {
        secondaryInfoRelay.asDriver()
    }

    var balanceDriver: Driver<String?> {
        balanceRelay.asDriver()
    }

    var balanceErrorDriver: Driver<Bool> {
        balanceErrorRelay.asDriver()
    }

    var tokenCodeDriver: Driver<String?> {
        tokenCodeRelay.asDriver()
    }

}
