class RestoreAccountsPresenter {
    private let router: IRestoreAccountsRouter

    private let accounts = RestoreType.allCases.map { RestoreAccountViewItem(title: $0.title, coinCodes: $0.coinCodes) }

    init(router: IRestoreAccountsRouter) {
        self.router = router
    }

}

extension RestoreAccountsPresenter: IRestoreAccountsViewDelegate {

    var itemsCount: Int {
        return accounts.count
    }

    func item(index: Int) -> RestoreAccountViewItem {
        return accounts[index]
    }

    func didTapRestore(index: Int) {
        let type = RestoreType(rawValue: index) ?? RestoreType.words12
        router.showRestore(type: type)
    }

}
