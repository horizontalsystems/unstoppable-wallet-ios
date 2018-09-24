import Foundation
import RxSwift

class PinPresenter {

    let interactor: IPinInteractor
    let router: IPinRouter
    weak var view: IPinView?

    init(interactor: IPinInteractor, router: IPinRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension PinPresenter: IPinInteractorDelegate {

    func highlightPinDot(index: Int) {
        view?.highlightPinDot(at: index)
    }

    @objc func bind(pinLength: Int) {
        fatalError("must be overridden")
    }

    func onWrongPin(clean: Bool = false) {
        view?.onWrongPin(clean: clean)
    }

}

extension PinPresenter: IPinViewDelegate {

    @objc func viewDidLoad() {
        interactor.viewDidLoad()
    }

    @objc func onEnter(pin: String?) {
        interactor.onEnter(pin: pin)
    }

}
