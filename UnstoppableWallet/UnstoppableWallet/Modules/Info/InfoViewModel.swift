import UIKit

protocol InfoDataSourceNew {
    var viewItems: [InfoViewModel.ViewItem] { get }
}

class InfoViewModel {
    let dataSource: InfoDataSourceNew

    init(dataSource: InfoDataSourceNew) {
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
