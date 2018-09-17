import Foundation
import RxSwift

class UnlockEditPinPresenter: PinPresenter {

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: "unlock_edit_pin.title".localized, infoText: "unlock_edit_pin.info".localized, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

}

extension UnlockEditPinPresenter: IUnlockEditPinInteractorDelegate {
    func onUnlockEdit() {
        router.onUnlockEdit()
    }
}
