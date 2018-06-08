import Foundation

class BalancePresenter {

    private let router: BalanceRouterProtocol

    init(router: BalanceRouterProtocol) {
        self.router = router
    }

}

extension BalancePresenter: BalanceViewDelegate {

}
