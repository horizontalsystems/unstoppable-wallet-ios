import Foundation
import RxSwift
import WalletKit

class UnlockPinInteractor: PinInteractor {
    var setDelegate: IUnlockPinInteractorDelegate? { return delegate as? IUnlockPinInteractorDelegate }

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)

        if let pin = pin, pin.count == pinLength {
            print("check pin")
        }
    }

}
