import RxSwift
import RxCocoa
import MarketKit

protocol ICoinToggleViewModel {
    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> { get }

    func onEnable(uid: String)
    func onDisable(uid: String)
    func onTapSettings(uid: String)
    func onUpdate(filter: String)
}

class CoinToggleViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String
        let placeholderImageName: String?
        let title: String
        let subtitle: String
        let state: ViewItemState

        init(fullCoin: FullCoin, state: ViewItemState) {
            uid = fullCoin.coin.uid
            imageUrl = fullCoin.coin.imageUrl
            placeholderImageName = fullCoin.placeholderImageName
            title = fullCoin.coin.name
            subtitle = fullCoin.coin.code
            self.state = state
        }
    }

    enum ViewItemState {
        case toggleVisible(enabled: Bool, hasSettings: Bool)
        case toggleHidden
    }

}
