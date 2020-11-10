import RxSwift
import RxCocoa
import UniswapKit

class SwapCoinCardViewModel {
    private static let unavailableBalanceIndex = 0
    private static let maxValidDecimals = 8

    let disposeBag = DisposeBag()

    let service: SwapServiceNew
    let tradeService: SwapTradeService
    let coinService: SwapCoinService

    let decimalParser: IAmountDecimalParser
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

    private var validDecimals = SwapCoinCardViewModel.maxValidDecimals

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

    init(service: SwapServiceNew, tradeService: SwapTradeService, coinService: SwapCoinService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.tradeService = tradeService
        self.coinService = coinService
        self.decimalParser = decimalParser

        titleRelay.accept(_description)

        subscribeToService()
    }

    func subscribeToService() {
        handle(tradeType: tradeService.tradeType)
        subscribe(disposeBag, tradeService.tradeTypeObservable) { [weak self] in self?.handle(tradeType: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.handle(errors: $0) }
    }

    private func handle(tradeType: TradeType) {
        isEstimatedRelay.accept(tradeType != type)
    }

    func update(amount: Decimal?) {
        guard type != tradeService.tradeType else {
            return
        }

        decimalFormatter.maximumFractionDigits = validDecimals
        let amountString = amount.flatMap { decimalFormatter.string(from: $0 as NSNumber) }

        amountRelay.accept(amountString)
    }

    func handle(coin: Coin?) {
        let max = SwapCoinCardViewModel.maxValidDecimals
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
    }

    func onChange(amount: String?) {
    }

    var tokensForSelection: [SwapModule.CoinBalanceItem] {
        []
    }

    func onSelect(coin: SwapModule.CoinBalanceItem) {
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

}
