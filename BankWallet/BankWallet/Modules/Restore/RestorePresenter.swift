class RestorePresenter {
    weak var view: IRestoreView?

    private let router: IRestoreRouter
    private let predefinedAccountTypes: [PredefinedAccountType]

    init(router: IRestoreRouter, predefinedAccountTypeManager: IPredefinedAccountTypeManager) {
        self.router = router
        predefinedAccountTypes = predefinedAccountTypeManager.allTypes
    }

}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        let viewItems = predefinedAccountTypes.map { AccountTypeViewItem(title: $0.title, coinCodes: $0.coinCodes) }
        view?.set(accountTypes: viewItems)
    }

    func didSelect(index: Int) {
        router.showRestore(predefinedAccountType: predefinedAccountTypes[index])
    }

}
