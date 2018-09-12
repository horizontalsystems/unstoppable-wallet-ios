import Foundation
import RxSwift

class SetPinPresenter: PinPresenter {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: "set_pin_controller.title".localized, infoText: "set_pin_controller.info".localized, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

    override func onSet(pin: String) {
        router.onSet(pin: pin)
    }

}
