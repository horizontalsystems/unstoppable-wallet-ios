import UIKit

class DepositPresenter {

    let interactor: IDepositInteractor
    let router: IDepositRouter
    weak var view: IDepositView?

    init(interactor: IDepositInteractor, router: IDepositRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension DepositPresenter: IDepositInteractorDelegate {

    func didGetAddressItems(items: [AddressItem]) {
        router.showView(with: items)
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    func share(address: String) {
        router.share(address: address)
    }

}

extension DepositPresenter: IDepositViewDelegate {

    func viewDidLoad() {
        interactor.getAddressItems()
    }

    func refresh() {

    }

    func onCopy(index: Int) {
        interactor.onCopy(index: index)
    }

    func onShare(index: Int) {
        interactor.onShare(index: index)
    }

}
