import UIKit

class SortTypeViewController: AlertViewControllerNew {

    init(delegate: IAlertViewDelegate) {
        super.init(alertTitle: "balance.sort.header".localized, delegate: delegate)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
