import UIKit

protocol ISendAccountView: class {
    func set(error: Error?)
}

protocol ISendAccountViewDelegate {
    func onOpenScan(controller: UIViewController)
    func onChange(account: String?)
}

protocol ISendAccountInteractor {
    var valueFromPasteboard: String? { get }
}

protocol ISendAccountModule: AnyObject {
    var delegate: ISendAccountDelegate? { get set }

    var currentAccount: String? { get }
    func validAccount() throws -> String
}

protocol ISendAccountDelegate: class {
    func validate(account: String) throws

    func onUpdateAccount()
}

protocol ISendAccountRouter {
    func openScanQrCode(controller: UIViewController)
}
