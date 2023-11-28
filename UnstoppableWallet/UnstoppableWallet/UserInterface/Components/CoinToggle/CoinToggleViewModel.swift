import MarketKit
import RxCocoa
import RxSwift

protocol ICoinToggleViewModel {
    var viewItemsDriver: Driver<[CoinToggleViewModel.ViewItem]> { get }

    func onEnable(uid: String)
    func onDisable(uid: String)
    func onTapSettings(uid: String)
    func onTapInfo(uid: String)
    func onUpdate(filter: String)
}

enum CoinToggleViewModel {
    struct ViewItem {
        let uid: String
        let imageUrl: String
        let placeholderImageName: String?
        let title: String
        let subtitle: String
        let badge: String?
        let state: ViewItemState
    }

    enum ViewItemState {
        case toggleVisible(enabled: Bool, hasSettings: Bool, hasInfo: Bool)
        case toggleHidden(notSupportedReason: String)
    }
}
