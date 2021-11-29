import RxSwift
import RxCocoa
import MarketKit

protocol ICoinToggleViewModel {
    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> { get }

    func onEnable(fullCoin: FullCoin)
    func onDisable(coin: Coin)
    func onTapSettings(fullCoin: FullCoin)
    func onUpdate(filter: String)
}

class CoinToggleViewModel {

    struct ViewItem {
        let fullCoin: FullCoin
        let state: ViewItemState
    }

    enum ViewItemState {
        case toggleVisible(enabled: Bool, hasSettings: Bool)
        case toggleHidden
    }

}
