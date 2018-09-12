import Foundation
import RxSwift

class ConfirmPinPresenter: PinPresenter {

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: "confirm_pin_controller.title".localized, infoText: "confirm_pin_controller.info".localized, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

}

extension ConfirmPinPresenter: IConfirmPinInteractorDelegate {

    func onConfirm() {
        HudHelper.instance.showSuccess()
        router.onConfirm()
    }

}
