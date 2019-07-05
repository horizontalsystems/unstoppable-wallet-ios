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
}

protocol IRestoreInteractorDelegate: class {
    func didRestore()
}

protocol IRestoreRouter {
    func showRestoreWords()
    func close()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(accountType: AccountType, syncMode: SyncMode?)
}
