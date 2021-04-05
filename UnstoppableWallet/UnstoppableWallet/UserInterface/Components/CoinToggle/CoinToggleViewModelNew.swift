import RxSwift
import RxCocoa
import CoinKit

protocol ICoinToggleViewModelNew {
    var viewStateDriver: Driver<CoinToggleViewModelNew.ViewState> { get }

    func onEnable(coin: Coin)
    func onDisable(coin: Coin)
    func onTapSettings(coin: Coin)
    func onUpdate(filter: String?)
}

class CoinToggleViewModelNew {

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
