import Foundation
import RxSwift

class PinPresenter {

    let interactor: ISetPinInteractor
    let router: IPinRouter
    weak var view: IPinView?

    init(interactor: ISetPinInteractor, router: IPinRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension PinPresenter: ISetPinInteractorDelegate {

    func highlightPinDot(index: Int) {
        view?.highlightPinDot(at: index)
    }

    @objc func bind(pinLength: Int) {
        fatalError("must be overridden")
    }

    @objc func onSet(pin: String) {
        fatalError("must be overridden")
    }

    @objc func onConfirm() {
        fatalError("must be overridden")
    }

    @objc func onWrongPin() {
        fatalError("must be overridden")
    }

}

extension PinPresenter: IPinViewDelegate {

    @objc func viewDidLoad() {
        interactor.viewDidLoad()
    }

    @objc func onPinChange(pin: String?) {
        interactor.onPinChange(pin: pin)
    }

}
