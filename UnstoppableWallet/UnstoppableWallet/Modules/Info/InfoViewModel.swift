import UIKit

protocol InfoDataSource {
    var title: String { get }
    var viewItems: [InfoViewModel.ViewItem] { get }
}

class InfoViewModel {
    let dataSource: InfoDataSource

    init(dataSource: InfoDataSource) {
        self.dataSource = dataSource
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
