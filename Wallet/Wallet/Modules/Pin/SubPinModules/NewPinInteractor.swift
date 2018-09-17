import Foundation
import RxSwift
import WalletKit

class NewPinInteractor: PinInteractor {
    var setDelegate: INewPinInteractorDelegate? { return delegate as? INewPinInteractorDelegate }

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)

        if let pin = pin, pin.count == pinLength {
            setDelegate?.onSet(pin: pin)
        }
    }

}
