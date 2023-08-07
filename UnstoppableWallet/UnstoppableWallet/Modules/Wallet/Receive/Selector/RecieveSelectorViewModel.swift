import Foundation

protocol IReceiveSelectorViewModel {
    associatedtype Item

    var title: String { get }
    var topDescription: String { get }
    var highlightedBottomDescription: String? { get }

    var viewItems: [ReceiveSelectorViewModel.ViewItem] { get }
    func item(uid: String) -> Item?
}

class ReceiveSelectorViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String?
        let title: String
        let subtitle: String
    }

}
