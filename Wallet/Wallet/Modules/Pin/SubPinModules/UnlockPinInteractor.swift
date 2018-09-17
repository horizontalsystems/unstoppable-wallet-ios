import Foundation
import RxSwift
import WalletKit

class UnlockPinInteractor: PinInteractor {
    var unlockDelegate: IUnlockPinInteractorDelegate? { return delegate as? IUnlockPinInteractorDelegate }

    let unlockHelper: UnlockHelper

    init(unlockHelper: UnlockHelper) {
        self.unlockHelper = unlockHelper
    }

    override func onPinChange(pin: String?) {
        super.onPinChange(pin: pin)

        if let pin = pin, pin.count == pinLength, unlockHelper.validate(pin) {
            unlockDelegate?.onUnlock()
        }
    }

}
