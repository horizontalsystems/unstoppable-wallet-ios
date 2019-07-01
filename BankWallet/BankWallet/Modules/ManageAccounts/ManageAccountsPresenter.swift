class ManageAccountsPresenter {
    private let interactor: IManageAccountsInteractor
    private let router: IManageAccountsRouter

    weak var view: IManageAccountsView?

    init(interactor: IManageAccountsInteractor, router: IManageAccountsRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension ManageAccountsPresenter: IManageAccountsViewDelegate {

    func viewDidLoad() {
        view?.show(accounts: interactor.accounts)
    }

}

extension ManageAccountsPresenter: IManageAccountsInteractorDelegate {

}
