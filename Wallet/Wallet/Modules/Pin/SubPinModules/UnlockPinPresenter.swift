import Foundation
import RxSwift

class UnlockPinPresenter: PinPresenter {

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: nil, infoText: "unlock_pin_controller.info".localized, infoFont: PinTheme.infoFontNoNavigation, infoAttachToTop: false)
    }

    deinit {
        print("deinit \(self)")
    }

}

extension UnlockPinPresenter: IUnlockPinInteractorDelegate {
    func onUnlock() {
        router.onUnlock()
    }
}
