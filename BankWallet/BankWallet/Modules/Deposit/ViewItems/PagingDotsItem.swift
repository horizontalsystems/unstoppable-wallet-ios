import Foundation
import ActionSheet

class PagingDotsItem: BaseActionItem {
    var pagesCount: Int
    var currentPage: Int = 0

    var updateView: (() -> ())?

    init(pagesCount: Int, tag: Int? = nil, hidden: Bool = false, required: Bool = false) {
        self.pagesCount = pagesCount

        super.init(cellType: PagingDotsItemView.self, tag: tag, hidden: hidden, required: required)

        showSeparator = false
        height = 30
    }

}
