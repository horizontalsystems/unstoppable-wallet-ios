import Foundation

class AddErc20TokenPresenter {
    weak var view: IAddErc20TokenView?

    private let interactor: IAddErc20TokenInteractor
    private let router: IAddErc20TokenRouter

    init(interactor: IAddErc20TokenInteractor, router: IAddErc20TokenRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenViewDelegate {

    func onTapPasteAddress() {
        view?.set(address: "abcdef2736623b87237i723bi76v32iu6i276v8236i7o")
        view?.set(spinnerVisible: true)

        view?.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.view?.set(spinnerVisible: false)
            self?.view?.set(viewItem: AddErc20TokenModule.ViewItem(coinName: "Huobi", symbol: "HBO", decimals: 18))
            self?.view?.set(buttonVisible: true)

            self?.view?.refresh()
        }

    }

    func onTapDeleteAddress() {
        view?.set(address: nil)
        view?.set(viewItem: nil)
        view?.set(buttonVisible: false)

        view?.refresh()
    }

    func onTapAddButton() {

    }

    func onTapCancel() {
        router.close()
    }

}

extension AddErc20TokenPresenter: IAddErc20TokenInteractorDelegate {
}
