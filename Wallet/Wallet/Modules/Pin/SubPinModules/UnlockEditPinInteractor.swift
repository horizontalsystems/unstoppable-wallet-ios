import Foundation
import RxSwift
import WalletKit

class UnlockEditPinInteractor: PinInteractor {
    var unlockDelegate: IUnlockEditPinInteractorDelegate? { return delegate as? IUnlockEditPinInteractorDelegate }

    let unlockHelper: UnlockHelper

    init(unlockHelper: UnlockHelper) {
        self.unlockHelper = unlockHelper
    }

    override func onEnter(pin: String?) {
        super.onEnter(pin: pin)

        if let pin = pin, pin.count == pinLength {
            if unlockHelper.validate(pin) {
                unlockDelegate?.onUnlockEdit()
            } else {
                unlockDelegate?.onWrongPin(clean: true)
            }
        }
    }

}
