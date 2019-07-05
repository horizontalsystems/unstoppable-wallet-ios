protocol IRestoreView: class {
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    var typesCount: Int { get }
    func type(index: Int) -> PredefinedAccountType
    func didSelect(index: Int)
    func didTapCancel()
}

protocol IRestoreInteractor {
    var allTypes: [PredefinedAccountType] { get }
    func createAccount(accountType: AccountType, syncMode: SyncMode?)
}

protocol IRestoreInteractorDelegate: class {
}

protocol IRestoreRouter {
    func showRestoreWords(delegate: IRestoreDelegate)
    func close()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(accountType: AccountType, syncMode: SyncMode?)
}
