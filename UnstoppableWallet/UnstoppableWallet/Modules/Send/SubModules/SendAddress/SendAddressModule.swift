import UIKit

protocol ISendAddressViewDelegate {
    func onOpenScan(controller: UIViewController)
}

protocol ISendAddressModule: AnyObject {
    var delegate: ISendAddressDelegate? { get set }

    var currentAddress: Address? { get }
    func validateAddress() throws
    func validAddress() throws -> Address
}

protocol ISendAddressDelegate: AnyObject {
    func validate(address: String) throws

    func onUpdateAddress()
    func onUpdate(amount: Decimal)
}

protocol ISendAddressRouter {
    func openScan(controller: UIViewController)
}
