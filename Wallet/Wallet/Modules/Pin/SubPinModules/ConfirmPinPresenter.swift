import Foundation
import RxSwift

class ConfirmPinPresenter: PinPresenter {
    var title: String?
    var info: String?

    init(interactor: IPinInteractor, router: IPinRouter, title: String?, info: String?) {
        super.init(interactor: interactor, router: router)
        self.title = title
        self.info = info
    }

    override func bind(pinLength: Int) {
        view?.bind(pinLength: pinLength, title: title, infoText: info, infoFont: PinTheme.infoFontRegular, infoAttachToTop: true)
    }

}

extension ConfirmPinPresenter: IConfirmPinInteractorDelegate {

    func onConfirm() {
        router.onConfirm()
    }

}
