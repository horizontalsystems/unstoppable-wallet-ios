import Foundation
import RxSwift
import WalletKit

class ConfirmPinInteractor: PinInteractor {
    var confirmDelegate: IConfirmPinInteractorDelegate? { return delegate as? IConfirmPinInteractorDelegate }

    var pinToConfirm: String
    var saveAttempts = 0
    let maxSaveAttempts = 2

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
        } else {
            delegate?.onWrongPin()
        }
    }

    func save(pin: String) {
        saveAttempts += 1
        do {
            try UnlockHelper.shared.store(pin: pin)
            confirmDelegate?.onConfirm()
        } catch {
            if saveAttempts < maxSaveAttempts {
                save(pin: pin)
            } else {
                HudHelper.instance.showError(title: "unlock.cant_save_pin".localized)
            }
        }
    }

}
