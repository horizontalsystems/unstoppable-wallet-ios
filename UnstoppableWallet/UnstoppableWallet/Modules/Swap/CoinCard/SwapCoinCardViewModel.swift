import RxSwift
import RxCocoa
import UniswapKit

class SwapCoinCardViewModel {
    private static let unavailableBalanceIndex = 0
    private static let maxValidDecimals = 8

    let disposeBag = DisposeBag()

    private let coinCardService: ISwapCoinCardService
    private let fiatService: FiatService

    let decimalParser: IAmountDecimalParser

    private let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ""
        return formatter
    }()

    var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    var amountRelay = BehaviorRelay<String?>(value: nil)
    var balanceRelay = BehaviorRelay<String?>(value: nil)
    var balanceErrorRelay = BehaviorRelay<Bool>(value: false)
    var tokenCodeRelay = BehaviorRelay<String?>(value: nil)

    private var validDecimals = SwapCoinCardViewModel.maxValidDecimals

    init(coinCardService: ISwapCoinCardService, fiatService: FiatService, decimalParser: IAmountDecimalParser) {
        self.coinCardService = coinCardService
        self.fiatService = fiatService
        self.decimalParser = decimalParser

        subscribeToService()
    }

    func subscribeToService() {
        sync(estimated: coinCardService.isEstimated)
        sync(amount: coinCardService.amount)
        sync(coin: coinCardService.coin)
        sync(balance: coinCardService.balance)

        subscribe(disposeBag, coinCardService.isEstimatedObservable) { [weak self] in self?.sync(estimated: $0) }
        subscribe(disposeBag, coinCardService.amountObservable) { [weak self] in self?.sync(amount: $0) }
        subscribe(disposeBag, coinCardService.coinObservable) { [weak self] in self?.sync(coin: $0) }
        subscribe(disposeBag, coinCardService.balanceObservable) { [weak self] in self?.sync(balance: $0) }
        subscribe(disposeBag, coinCardService.errorObservable) { [weak self] in self?.sync(error: $0) }
    }

    private func sync(estimated: Bool) {
        isEstimatedRelay.accept(estimated)
    }

    func sync(amount: Decimal?) {
        fiatService.amount = amount

        decimalFormatter.maximumFractionDigits = validDecimals
        let amountString = amount.flatMap { decimalFormatter.string(from: $0 as NSNumber) }

        amountRelay.accept(amountString)
    }

    func sync(coin: Coin?) {
        let max = SwapCoinCardViewModel.maxValidDecimals
        validDecimals = min(max, (coin?.decimal ?? max))

        fiatService.coin = coin
        tokenCodeRelay.accept(coin?.code)
    }

    func sync(balance: Decimal?) {
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

    func sync(error: Error?) {
        balanceErrorRelay.accept(error != nil)
    }

    func onChange(amount: String?) {
        let amount = decimalParser.parseAnyDecimal(from: amount)

        fiatService.amount = amount
        coinCardService.onChange(amount: amount)
    }

    func onSelect(coin: Coin) {
        fiatService.coin = coin
        coinCardService.onChange(coin: coin)
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
