import Foundation
import RxSwift
import WalletKit

class UnlockPinInteractor: PinInteractor {
    var unlockDelegate: IUnlockPinInteractorDelegate? { return delegate as? IUnlockPinInteractorDelegate }

    let unlockHelper: UnlockHelper
    let biometricHelper: BiometricHelper

    init(unlockHelper: UnlockHelper, biometricHelper: BiometricHelper) {
        self.unlockHelper = unlockHelper
        self.biometricHelper = biometricHelper
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if biometricHelper.isOn {
            biometricHelper.validate() { [weak self] success in
                if success {
                    self?.unlockDelegate?.onUnlock()
                }
            }
        }
    }

    override func onEnter(pin: String?) {
        super.onEnter(pin: pin)
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
