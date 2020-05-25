import UIKit

class BitcoinHodlingRouter {
}

extension BitcoinHodlingRouter {

    static func module() -> UIViewController {
        let interactor = BitcoinHodlingInteractor(localStorage: App.shared.localStorage)
        let presenter = BitcoinHodlingPresenter(interactor: interactor)
        let view = BitcoinHodlingViewController(delegate: presenter)

        presenter.view = view

        return view
    }

}
