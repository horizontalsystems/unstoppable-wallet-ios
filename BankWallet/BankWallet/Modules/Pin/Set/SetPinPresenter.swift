import Foundation

class SetPinPresenter: ManagePinPresenter {

    private let router: ISetPinRouter

    init(interactor: IPinInteractor, router: ISetPinRouter) {
        self.router = router
        super.init(interactor: interactor, pages: [.enter, .confirm])
    }

    override func viewDidLoad() {
        view?.set(title: "set_pin.title")

        for page in pages {
            switch page {
            case .enter: view?.addPage(withDescription: "set_pin.info", showKeyboard: true)
            case .confirm: view?.addPage(withDescription: "set_pin.confirm.info", showKeyboard: true)
            default: ()
            }
        }
    }

    override func onCancel() {
    }

    override func didSavePin() {
        router.navigateToMain()
    }

}
