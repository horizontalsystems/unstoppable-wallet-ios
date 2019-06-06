import Foundation

class EditPinPresenter: ManagePinPresenter {

    let router: IEditPinRouter

    init(interactor: IPinInteractor, router: IEditPinRouter) {
        self.router = router
        super.init(interactor: interactor, pages: [.unlock, .enter, .confirm])
    }

    override func viewDidLoad() {
        view?.set(title: "edit_pin.title")

        for page in pages {
            switch page {
            case .unlock: view?.addPage(withDescription: "edit_pin.unlock_info")
            case .enter: view?.addPage(withDescription: "edit_pin.new_pin_info")
            case .confirm: view?.addPage(withDescription: "button.confirm")
            }
        }

        view?.showCancel()
    }

    override func onCancel() {
        router.dismiss()
    }

    override func didSavePin() {
        view?.showSuccess()
        router.dismiss()
    }

}
