import RxSwift
import RxCocoa
import UniswapKit

class BaseSwapInputViewModel {
    static private let unavailableBalanceIndex = 0
    static private let maxValidDecimals = 8

    let disposeBag = DisposeBag()

    let service: SwapService

    private let decimalParser: IAmountDecimalParser
    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    var titleRelay = BehaviorRelay<String?>(value: nil)
    var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    var amountRelay = BehaviorRelay<String?>(value: nil)
    var balanceRelay = BehaviorRelay<String?>(value: nil)
    var balanceErrorRelay = BehaviorRelay<Bool>(value: false)
    var tokenCodeRelay = BehaviorRelay<String?>(value: nil)

    private var validDecimals = BaseSwapInputViewModel.maxValidDecimals

    var balanceErrors = ContainerState<Int, Error>()

    var type: TradeType {
        fatalError("Must be implemented by Concrete subclass.")
    }

    var _description: String {
        fatalError("Must be implemented by Concrete subclass.")
    }

    var coin: Coin? {
        fatalError("Must be implemented by Concrete subclass.")
    }

    init(service: SwapService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        titleRelay.accept(_description)

        subscribeToService()
    }

    func subscribeToService() {
        handle(estimated: service.estimated)
        subscribe(disposeBag, service.estimatedObservable) { [weak self] in self?.handle(estimated: $0) }
        subscribe(disposeBag, service.validationErrorsObservable) { [weak self] in self?.handle(errors: $0) }
    }

    private func handle(estimated: TradeType) {
        isEstimatedRelay.accept(estimated != type)
    }

    func update(amount: Decimal?) {
        guard self.type != service.estimated else {
            return
        }

        decimalFormatter.maximumFractionDigits = validDecimals
        let amountString = amount.flatMap { decimalFormatter.string(from: $0 as NSNumber) }

        amountRelay.accept(amountString)
    }

    func handle(coin: Coin?) {
        let max = SwapToInputViewModel.maxValidDecimals
        validDecimals = min(max, (coin?.decimal ?? max))

        tokenCodeRelay.accept(coin?.code)
    }

    func handle(balance: Decimal?) {
        guard let coin = self.coin else {
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

    func handle(errors: [Error]) {
        let error = errors.first(where: { SwapValidationError.unavailableBalance(type: type) == $0 as? SwapValidationError })
        balanceErrors.set(to: Self.unavailableBalanceIndex, value: error)

        balanceErrorRelay.accept(balanceErrors.first != nil)
    }

}

extension BaseSwapInputViewModel {

    var isEstimated: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

    func isValid(amount: String?) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        return amount.decimalCount <= validDecimals
    }

    var description: Driver<String?> {
        titleRelay.asDriver()
    }

    var amount: Driver<String?> {
        amountRelay.asDriver()
    }

    var balance: Driver<String?> {
        balanceRelay.asDriver()
    }

    var balanceError: Driver<Bool> {
        balanceErrorRelay.asDriver()
    }

    var tokenCode: Driver<String?> {
        tokenCodeRelay.asDriver()
    }

    func onChange(amount: String?) {
        service.onChange(type: type, amount: decimalParser.parseAnyDecimal(from: amount))
    }

    var tokensForSelection: [SwapModule.CoinBalanceItem] {
        service.tokensForSelection(type: type)
    }

    func onSelect(coin: SwapModule.CoinBalanceItem) {
        service.onSelect(type: type, coin: coin.coin)
    }

}
