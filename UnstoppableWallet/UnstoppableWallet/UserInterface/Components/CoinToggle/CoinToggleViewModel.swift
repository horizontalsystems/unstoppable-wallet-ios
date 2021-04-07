import RxSwift
import RxCocoa
import CoinKit

protocol ICoinToggleViewModel {
    var viewStateDriver: Driver<CoinToggleViewModel.ViewState> { get }

    func onEnable(coin: Coin)
    func onDisable(coin: Coin)
    func onTapSettings(coin: Coin)
    func onUpdate(filter: String?)
}

class CoinToggleViewModel {

    struct ViewState {
        let featuredViewItems: [ViewItem]
        let viewItems: [ViewItem]

        static var empty: ViewState {
            ViewState(featuredViewItems: [], viewItems: [])
        }
    }

    struct ViewItem {
        let coin: Coin
        let hasSettings: Bool
        let enabled: Bool
    }

}
