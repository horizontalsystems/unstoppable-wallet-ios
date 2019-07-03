class RestoreAccountsPresenter {
    private let router: IRestoreAccountsRouter

    private let accountTypes = PredefinedAccountType.allCases

    init(router: IRestoreAccountsRouter) {
        self.router = router
    }

}

extension RestoreAccountsPresenter: IRestoreAccountsViewDelegate {

    var itemsCount: Int {
        return accountTypes.count
    }

    func item(index: Int) -> PredefinedAccountType {
        return accountTypes[index]
    }

    func didTapRestore(index: Int) {
        router.showRestore(type: accountTypes[index])
    }

}
