import RxSwift
import RxCocoa
import UniswapKit

class SwapFromInputPresenter {
    private let disposeBag = DisposeBag()

    private let service: Swap2Service
    private let decimalParser: ISendAmountDecimalParser
//    private let decimalFormatter: NumberFormatter = {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        formatter.groupingSeparator = ""
//        return formatter
//    }()

    private var isEstimatedRelay = BehaviorRelay<Bool>(value: false)
    private var amountRelay = BehaviorRelay<String?>(value: nil)
    private var tokenCodeRelay = BehaviorRelay<String?>(value: nil)

    init(service: Swap2Service, decimalParser: ISendAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.estimated) { [weak self] estimated in self?.isEstimatedRelay.accept(estimated == .exactOut) }
        subscribe(disposeBag, service.amountIn) { [weak self] amount in self?.update(amount: amount) }
        subscribe(disposeBag, service.coinIn) { [weak self] coin in self?.tokenCodeRelay.accept(coin.code) }
    }

//    private func format(coinValue: CoinValue) -> String? {
//        decimalFormatter.maximumFractionDigits = min(coinValue.coin.decimal, 8)
//        return decimalFormatter.string(from: coinValue.value as NSNumber)
//    }

    private func update(amount: Decimal?) {
        // TODO: right converting
        amountRelay.accept(amount?.description)
    }

}

// TODO: handle changes from base service
extension SwapFromInputPresenter: ISwapInputPresenter {

    var description: String {
        "swap.you_get"
    }

    var isEstimated: Driver<Bool> {
        isEstimatedRelay.asDriver()
    }

    func isValid(amount: String?) -> Bool {
        true
//        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
//            return false
//        }
//
//        return service.isValid(type: .exactIn, amount: amount)
    }

    var amount: Driver<String?> {
        amountRelay.asDriver()
    }

    var tokenCode: Driver<String?> {
        tokenCodeRelay.asDriver()
    }

    func onChange(amount: String?) {
        service.onChange(type: .exactIn, amount: amount)
    }

    var tokensForSelection: [Coin] {
        service.tokensForSelection(type: .exactIn)
    }

    func onSelect(coin: Coin) {
        service.onSelect(type: .exactIn, coin: coin)
    }

}