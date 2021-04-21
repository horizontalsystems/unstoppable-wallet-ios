import UIKit
import ThemeKit

class MarketWatchlistViewController: MarketListViewController {
    private let cautionCell = CautionCell()

    override func viewDidLoad() {
        super.viewDidLoad()

        cautionCell.cautionImage = UIImage(named: "rate_48")
        cautionCell.cautionText = "market_watchlist.empty.caption".localized
    }

    override var emptyCell: UITableViewCell? {
        cautionCell
    }

    override var headerAlwaysVisible: Bool {
        false
    }

}
