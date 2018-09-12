import Foundation
import RxSwift
import WalletKit

class SetPinInteractor: PinInteractor {
    var setDelegate: ISetPinInteractorDelegate? { return delegate as? ISetPinInteractorDelegate }

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)

        if let pin = pin, pin.count == pinLength {
            setDelegate?.onSet(pin: pin)
        }
    }

}
