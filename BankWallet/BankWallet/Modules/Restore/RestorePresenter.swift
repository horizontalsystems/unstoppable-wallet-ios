class RestorePresenter {
    weak var view: IRestoreView?

    private let interactor: IRestoreInteractor
    private let router: IRestoreRouter

    private var types = [PredefinedAccountType]()

    init(interactor: IRestoreInteractor, router: IRestoreRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension RestorePresenter: IRestoreInteractorDelegate {
}

extension RestorePresenter: IRestoreViewDelegate {

    func viewDidLoad() {
        types = interactor.allTypes
    }

    var typesCount: Int {
        return types.count
    }

    func type(index: Int) -> PredefinedAccountType {
        return types[index]
    }

    func didSelect(index: Int) {
        switch types[index] {
        case .mnemonic: router.showRestoreWords(delegate: self)
        case .eos: ()
        case .binance: ()
        }
    }

    func didTapCancel() {
        router.close()
    }

}

extension RestorePresenter: IRestoreDelegate {

    func didRestore(accountType: AccountType, syncMode: SyncMode?) {
        interactor.createAccount(accountType: accountType, syncMode: syncMode)
        router.close()
    }

}
