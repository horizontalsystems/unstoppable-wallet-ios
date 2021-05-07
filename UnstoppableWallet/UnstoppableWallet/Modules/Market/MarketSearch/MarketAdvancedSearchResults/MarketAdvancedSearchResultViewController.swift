import UIKit
import ThemeKit

class MarketAdvancedSearchResultViewController: MarketListViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Results".localized
    }

    override var headerAlwaysVisible: Bool {
        false
    }

}
