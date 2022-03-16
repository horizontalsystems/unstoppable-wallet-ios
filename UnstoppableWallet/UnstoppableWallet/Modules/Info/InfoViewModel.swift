import UIKit

class InfoViewModel {
    let title: String
    let viewItems: [InfoViewModel.ViewItem]

    init(title: String, viewItems: [InfoViewModel.ViewItem]) {
        self.title = title
        self.viewItems = viewItems
    }

}

extension InfoViewModel {

    enum ViewItem {
        case separator
        case margin(height: CGFloat)
        case header(title: String)
        case header3Cell(string: String)
        case text(string: String)
        case button(title: String, url: String)
    }

}
