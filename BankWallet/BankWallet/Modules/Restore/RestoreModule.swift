protocol IRestoreView: class {
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    var typesCount: Int { get }
    func type(index: Int) -> PredefinedAccountType
    func didSelect(index: Int)
    func didTapCancel()
}

protocol IRestoreRouter {
    func showRestore(type: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate)
    func close()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account, syncMode: SyncMode?)
}

protocol IRestoreAccountTypeDelegate: AnyObject {
    func didRestore(accountType: AccountType, syncMode: SyncMode?)
}
