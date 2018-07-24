import UIKit
import GrouviActionSheet

class SendAlertModel: BaseAlertModel {

    let delegate: ISendViewDelegate

    init(viewDelegate: ISendViewDelegate) {
        self.delegate = viewDelegate

        super.init()
        delegate.onViewDidLoad()

    }

}

extension SendAlertModel: ISendView {

    func setAddress(address: String) {
        print("setAddress")
    }

    func setCurrency(code: String) {
        print("setCurrency")
    }

    func setAmount(amount: String?) {
        print("setAmount")
    }

    func setAmountHint(hint: String) {
        print("setAmountHint")
    }

    func closeView() {
        print("closeView")
    }

    func showError(error: Error) {
        print("showError")
    }

    func showSuccess() {
        print("showSuccess")
    }

}
