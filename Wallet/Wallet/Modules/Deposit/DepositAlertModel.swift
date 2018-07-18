import UIKit
import GrouviActionSheet

class DepositAlertModel: BaseAlertModel {

    let delegate: IDepositViewDelegate


    init(viewDelegate: IDepositViewDelegate) {
        self.delegate = viewDelegate

        super.init()
        delegate.viewDidLoad()
    }

}

extension DepositAlertModel: IDepositView {

}
