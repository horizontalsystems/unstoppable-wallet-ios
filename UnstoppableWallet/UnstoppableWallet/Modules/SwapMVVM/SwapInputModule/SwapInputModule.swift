import RxSwift
import RxCocoa
import UniswapKit

protocol ISwapInputViewModel {
    var description: String { get }
    var isEstimated: Driver<Bool> { get }
    var isLoading: Driver<Bool> { get }
    var amount: Driver<String?> { get }
    var tokenCode: Driver<String> { get }
    var tokensForSelection: [Coin] { get }

    func isValid(amount: String?) -> Bool
    func onChange(amount: String?)

    func onSelect(coin: Coin)
}

struct SwapInputModule {

    static func instance(type: TradeType, baseService: Swap2Service) -> UIView {
        let viewModel = SwapInputModuleViewModel(service: baseService)

        return SwapInputModuleView(viewModel: viewModel)
    }

}
