import Foundation

class TransactionsPresenter {

    private let router: TransactionsRouterProtocol

    init(router: TransactionsRouterProtocol) {
        self.router = router
    }

}

extension TransactionsPresenter: TransactionsViewDelegate {

}
