import Foundation
import RxSwift
import WalletKit

class EditPinInteractor: PinInteractor {
    var setDelegate: IEditPinInteractorDelegate? { return delegate as? IEditPinInteractorDelegate }

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)

        if let pin = pin, pin.count == pinLength {
            setDelegate?.onSet(pin: pin)
        }
    }

}
