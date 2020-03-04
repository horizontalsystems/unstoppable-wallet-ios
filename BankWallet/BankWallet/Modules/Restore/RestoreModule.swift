protocol IRestoreView: class {
    func set(accountTypes: [AccountTypeViewItem])
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IRestoreRouter {
    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate)
    func showSettings(delegate: IBlockchainSettingsDelegate)
    func showRestoreCoins(predefinedAccountType: PredefinedAccountType, accountType: AccountType, delegate: IRestoreCoinsDelegate)
    func showMain()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account)
}

protocol IRestoreSequenceFactory {
    func onAccountCheck(accountType: AccountType, predefinedAccountType: PredefinedAccountType?, settings: (() -> ()), coins: ((AccountType, PredefinedAccountType) -> ()))
    func onSettingsConfirm(accountType: AccountType?, predefinedAccountType: PredefinedAccountType?, coins: ((AccountType, PredefinedAccountType) -> ()))
}
