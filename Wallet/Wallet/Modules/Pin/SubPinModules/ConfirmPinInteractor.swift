import Foundation
import RxSwift
import WalletKit

class ConfirmPinInteractor: PinInteractor {
    var confirmDelegate: IConfirmPinInteractorDelegate? { return delegate as? IConfirmPinInteractorDelegate }

    var pinToConfirm: String

    init(pin: String) {
        pinToConfirm = pin
    }

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)
        guard let pin = pin, pin.count == pinLength else {
            return
        }

        if pin == pinToConfirm {
            save(pin: pin)
            confirmDelegate?.onConfirm()
        } else {
            delegate?.onWrongPin()
        }
    }

    func save(pin: String) {
        print("save pin")
    }

}
