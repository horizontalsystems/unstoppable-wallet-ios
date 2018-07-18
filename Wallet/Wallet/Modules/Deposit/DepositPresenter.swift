import Foundation
import WalletKit
import RealmSwift

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

}

extension DepositPresenter: IDepositViewDelegate {

    func viewDidLoad() {
    }

    func refresh() {

    }

    func share() {

    }

}
