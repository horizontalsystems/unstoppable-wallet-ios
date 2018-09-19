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
        guard let pin = pin, pin.count == pinLength else {
            return
        }

        if unlockHelper.validate(pin) {
            unlockDelegate?.onUnlock()
        } else {
            unlockDelegate?.onWrongPin(clean: true)
        }
    }

}
