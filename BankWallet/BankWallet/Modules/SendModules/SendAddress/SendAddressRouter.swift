import UIKit

class SendAddressRouter {
    weak var viewController: UIViewController?
}

extension SendAddressRouter: ISendAddressRouter {

    func scanQrCode(onCodeParse: ((String) -> ())?) {
        let scanController = ScanQRController()
        scanController.onCodeParse = onCodeParse
        viewController?.present(scanController, animated: true)
    }

}