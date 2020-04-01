protocol IRestoreView: class {
    func set(accountTypes: [AccountTypeViewItem])
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IRestoreRouter {
    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate)
    func showRestoreCoins(predefinedAccountType: PredefinedAccountType, accountType: AccountType, delegate: IRestoreCoinsDelegate?)
    func showMain()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account)
}

protocol IRestoreSequenceManager {
    func onAccountCheck(accountType: AccountType, predefinedAccountType: PredefinedAccountType?, coins: ((AccountType, PredefinedAccountType) -> ()))
    func onCoinsSelect(coins: [Coin], accountType: AccountType?, derivationSettings: [DerivationSetting], finish: () -> ()?)
}
