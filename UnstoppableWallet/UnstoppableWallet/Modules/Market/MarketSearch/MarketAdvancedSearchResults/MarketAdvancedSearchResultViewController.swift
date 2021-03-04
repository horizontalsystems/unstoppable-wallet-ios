import UIKit
import ThemeKit

class MarketAdvancedSearchResultViewController: MarketListViewController {

    init(listViewModel: MarketListViewModel) {
        super.init(listViewModel: listViewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Results".localized
    }

    override var headerAlwaysVisible: Bool {
        false
    }

}
