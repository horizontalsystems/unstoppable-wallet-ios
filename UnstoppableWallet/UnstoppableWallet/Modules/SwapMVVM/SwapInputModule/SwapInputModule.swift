import RxSwift
import RxCocoa
import UniswapKit

protocol ISwapInputPresenter {
    var description: String { get }
    var isEstimated: Driver<Bool> { get }
    var amount: Driver<String?> { get }
    var tokenCode: Driver<String?> { get }
    var tokensForSelection: [Coin] { get }

    func isValid(amount: String?) -> Bool
    func onChange(amount: String?)

    func onSelect(coin: Coin)
}
