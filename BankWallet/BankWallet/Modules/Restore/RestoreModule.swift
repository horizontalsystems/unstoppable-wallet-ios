protocol IRestoreView: class {
    func set(accountTypes: [AccountTypeViewItem])
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IRestoreRouter {
    func showRestore(defaultAccountType: DefaultAccountType, delegate: IRestoreAccountTypeDelegate)
    func notifyRestored(account: Account)
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
