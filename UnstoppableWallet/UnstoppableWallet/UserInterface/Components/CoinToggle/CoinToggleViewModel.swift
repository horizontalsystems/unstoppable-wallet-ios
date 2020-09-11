import RxSwift
import RxCocoa

protocol ICoinToggleViewModel {
    var viewStateDriver: Driver<CoinToggleViewModel.ViewState> { get }

    func onEnable(coin: Coin)
    func onDisable(coin: Coin)
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

    class ViewItem {
        let coin: Coin
        var state: ViewItemState

        init(coin: Coin, state: ViewItemState) {
            self.coin = coin
            self.state = state
        }
    }

    enum ViewItemState: CustomStringConvertible {
        case toggleHidden
        case toggleVisible(enabled: Bool)

        var description: String {
            switch self {
            case .toggleHidden: return "hidden"
            case .toggleVisible(let enabled): return "visible_\(enabled)"
            }
        }

    }

}
