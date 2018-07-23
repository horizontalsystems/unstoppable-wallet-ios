import Foundation
import WalletKit

protocol IDepositView: class {
}

protocol IDepositViewDelegate {
    func viewDidLoad()
    func refresh()
    func share()
}

protocol IDepositInteractor {
}

protocol IDepositInteractorDelegate: class {
}

protocol IDepositRouter {
}
