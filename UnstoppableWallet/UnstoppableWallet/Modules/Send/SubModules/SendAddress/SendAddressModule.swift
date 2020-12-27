import UIKit

protocol ISendAddressViewDelegate {
    func onOpenScan(controller: UIViewController)
}

protocol ISendAddressInteractor {
    func parse(address: String) -> (String, Decimal?)
}

protocol ISendAddressModule: AnyObject {
    var delegate: ISendAddressDelegate? { get set }

    var currentAddress: String? { get }
    func validateAddress() throws
    func validAddress() throws -> String
}

protocol ISendAddressDelegate: class {
    func validate(address: String) throws

    func onUpdateAddress()
    func onUpdate(amount: Decimal)
}

protocol ISendAddressRouter {
    func openScan(controller: UIViewController)
}
