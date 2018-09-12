import Foundation
import RxSwift

class ConfirmPinPresenter: PinPresenter {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: "confirm_pin_controller.title".localized, infoText: "confirm_pin_controller.info".localized, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

    override func onConfirm() {
        HudHelper.instance.showSuccess()
        router.onConfirm()
    }

    override func onWrongPin() {
        HudHelper.instance.showError(title: "confirm_pin_controller.wrong_pin".localized)
    }

}
