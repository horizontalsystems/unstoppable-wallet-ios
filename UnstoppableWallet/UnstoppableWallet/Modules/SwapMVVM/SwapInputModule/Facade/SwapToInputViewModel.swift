import RxSwift
import RxCocoa

class SwapToInputViewModel {
    private let service: Swap2Service

    init(service: Swap2Service) {
        self.service = service
    }

}

// TODO: handle changes from base service
extension SwapToInputViewModel: ISwapInputViewModel {
    var description: String {
        "swap.you_pay"
    }

    func isValid(amount: String?) -> Bool {
        fatalError("isValid(amount:) has not been implemented")
    }

    func onChange(amount: String?) {
    }

    var isEstimated: Driver<Bool> {
        fatalError("isEstimated has not been implemented")
    }

    var isLoading: Driver<Bool> {
        fatalError("isLoading has not been implemented")
    }

    var amount: Driver<String?> {
        fatalError("amount has not been implemented")
    }

    var tokenCode: Driver<String> {
        fatalError("tokenCode has not been implemented")
    }

    var tokensForSelection: [Coin] {
        fatalError("tokenForSelection has not been implemented")
    }

    func onTapTokenSelect() {
    }

    func onSelect(coin: Coin) {
    }
}