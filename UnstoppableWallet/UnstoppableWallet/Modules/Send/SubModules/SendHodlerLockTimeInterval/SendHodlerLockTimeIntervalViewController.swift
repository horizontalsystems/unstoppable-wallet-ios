import UIKit

class SendHodlerLockTimeIntervalViewController: AlertViewController {

    init(delegate: IAlertViewDelegate) {
        super.init(alertTitle: "send.hodler_locktime".localized, delegate: delegate)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
