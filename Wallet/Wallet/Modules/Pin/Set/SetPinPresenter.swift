import Foundation

class SetPinPresenter: ManagePinPresenter {

    private let router: ISetPinRouter

    init(interactor: IPinInteractor, router: ISetPinRouter) {
        self.router = router
        super.init(interactor: interactor, pages: [.enter, .confirm])
    }

    override func viewDidLoad() {
        view?.set(title: "set_pin_controller.title")

        for page in pages {
            switch page {
            case .enter: view?.addPage(withDescription: "set_pin_controller.info", showKeyboard: true)
            case .confirm: view?.addPage(withDescription: "confirm_pin_controller.info", showKeyboard: true)
            default: ()
            }
        }
    }

    override func onCancel() {
    }

    override func didSavePin() {
        router.dismiss()
    }

}
