import Foundation
import RxSwift
import WalletKit

class SetPinInteractor: PinInteractor {

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)

        if let pin = pin, pin.count == pinLength {
            delegate?.onSet(pin: pin)
        }
    }

}
