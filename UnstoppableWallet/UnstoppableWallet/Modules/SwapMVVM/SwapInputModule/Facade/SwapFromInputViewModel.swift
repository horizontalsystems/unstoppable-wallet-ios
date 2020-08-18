import RxSwift
import RxCocoa

class SwapFromInputViewModel {
    private let service: Swap2Service
    private let decimalParser: ISendAmountDecimalParser

    init(service: Swap2Service, decimalParser: ISendAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser
    }

}

// TODO: handle changes from base service
extension SwapFromInputViewModel: ISwapInputViewModel {

    var tokensForSelection: [Coin] {
        []
    }

    var description: String {
        "swap.you_get"
    }

    var isEstimated: Driver<Bool> {
        fatalError("isEstimated has not been implemented")
    }

    var isLoading: Driver<Bool> {
        fatalError("isLoading has not been implemented")
    }

    func isValid(amount: String?) -> Bool {
        guard let amount = decimalParser.parseAnyDecimal(from: amount) else {
            return false
        }

        return service.isValid(type: .exactIn, amount: amount)
    }

    var amount: Driver<String?> {
        fatalError("amount has not been implemented")
    }

    var tokenCode: Driver<String> {
        fatalError("tokenCode has not been implemented")
    }

    func onChange(amount: String?) {
    }

    func onTapTokenSelect() {
    }

    func onSelect(coin: Coin) {
    }
}