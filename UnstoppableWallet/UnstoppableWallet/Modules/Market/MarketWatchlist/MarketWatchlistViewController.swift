import UIKit
import ThemeKit

class MarketWatchlistViewController: MarketListViewController {
    private let cautionCell = CautionCell()

    init(listViewModel: MarketListViewModel) {
        super.init(listViewModel: listViewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
