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

}

extension PinPresenter: IPinViewDelegate {

    func viewDidLoad() {
    }

}
