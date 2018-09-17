import Foundation
import RxSwift

class EditPinPresenter: PinPresenter {

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: "edit_pin_controller.title".localized, infoText: "edit_pin_controller.info".localized, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

}

extension EditPinPresenter: IEditPinInteractorDelegate {

    func onSet(pin: String) {
        router.onSet(pin: pin)
    }

}
