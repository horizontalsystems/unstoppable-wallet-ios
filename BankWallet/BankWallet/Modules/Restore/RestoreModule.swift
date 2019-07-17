protocol IRestoreView: class {
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    var typesCount: Int { get }
    func type(index: Int) -> IPredefinedAccountType
    func didSelect(index: Int)
    func didTapCancel()
}

protocol IRestoreRouter {
    func showRestore(defaultAccountType: DefaultAccountType, delegate: IRestoreAccountTypeDelegate)
    func notifyRestored(account: Account)
    func close()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account)
}

protocol IRestoreAccountTypeDelegate: AnyObject {
    func didRestore(accountType: AccountType, syncMode: SyncMode?)
    func didCancelRestore()
}

extension IRestoreAccountTypeDelegate {

    func didCancelRestore() {
    }

}
