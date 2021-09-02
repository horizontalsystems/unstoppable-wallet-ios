import RxSwift
import RxCocoa
import MarketKit

protocol ICoinToggleViewModel {
    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> { get }

    func onEnable(marketCoin: MarketCoin)
    func onDisable(coin: Coin)
    func onTapSettings(marketCoin: MarketCoin)
    func onUpdate(filter: String)
}

class CoinToggleViewModel {

    struct ViewItem {
        let marketCoin: MarketCoin
        let state: ViewItemState
    }

    enum ViewItemState {
        case toggleVisible(enabled: Bool, hasSettings: Bool)
        case toggleHidden
    }

}
