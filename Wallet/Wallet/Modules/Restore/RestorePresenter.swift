import Foundation

class RestorePresenter {

    let delegate: RestorePresenterDelegate
    let router: RestoreRouterProtocol
    weak var view: RestoreViewProtocol?

    init(delegate: RestorePresenterDelegate, router: RestoreRouterProtocol) {
        self.delegate = delegate
        self.router = router
    }

}

extension RestorePresenter: RestoreViewDelegate {

    func cancelDidTap() {
        router.close()
    }

}
