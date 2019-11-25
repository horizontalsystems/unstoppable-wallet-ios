protocol IRestoreView: class {
    func set(accountTypes: [AccountTypeViewItem])
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IRestoreRouter {
    func showRestoreCoins(predefinedAccountType: PredefinedAccountType)
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account)
}

protocol IRestoreAccountTypeDelegate: AnyObject {
    func didRestore(accountType: AccountType)
    func didCancelRestore()
}

extension IRestoreAccountTypeDelegate {

    func didCancelRestore() {
    }

}
