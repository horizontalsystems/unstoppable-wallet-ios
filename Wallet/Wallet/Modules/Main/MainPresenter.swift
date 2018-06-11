import Foundation

class MainPresenter {

    let delegate: MainPresenterDelegate
    let router: MainRouterProtocol
    weak var view: MainViewProtocol?

    init(delegate: MainPresenterDelegate, router: MainRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension MainPresenter: MainPresenterProtocol {
}

extension MainPresenter: MainViewDelegate {
}
