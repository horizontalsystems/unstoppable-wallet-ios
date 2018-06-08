import Foundation

class MainPresenter {

    private let router: MainRouterProtocol

    init(router: MainRouterProtocol) {
        self.router = router
    }

}

extension MainPresenter: MainViewDelegate {

}
