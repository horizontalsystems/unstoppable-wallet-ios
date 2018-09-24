import Foundation
import RxSwift

class NewPinPresenter: PinPresenter {

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: "edit_pin_controller.title".localized, infoText: nil, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

}

extension NewPinPresenter: INewPinInteractorDelegate {

    func onSet(pin: String) {
        router.onSetNew(pin: pin)
    }

}
