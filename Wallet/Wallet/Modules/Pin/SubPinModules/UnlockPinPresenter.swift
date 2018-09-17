import Foundation
import RxSwift

class UnlockPinPresenter: PinPresenter {

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: nil, infoText: "unlock_pin_controller.info".localized, infoFont: PinTheme.infoFontNoNavigation, infoAttachToTop: false)
    }

}

extension UnlockPinPresenter: IUnlockPinInteractorDelegate {
}
