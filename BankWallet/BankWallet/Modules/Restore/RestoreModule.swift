protocol IRestoreView: class {
    func set(accountTypes: [AccountTypeViewItem])
}

protocol IRestoreViewDelegate {
    func viewDidLoad()
    func didSelect(index: Int)
}

protocol IRestoreRouter {
    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate)
    func showSettings(coins: [Coin], delegate: IBlockchainSettingsDelegate?)
    func showRestoreCoins(predefinedAccountType: PredefinedAccountType, accountType: AccountType, proceedMode: RestoreRouter.ProceedMode, delegate: IRestoreCoinsDelegate?)
    func showMain()
}

protocol IRestoreDelegate: AnyObject {
    func didRestore(account: Account)
}

protocol IRestoreSequenceFactory {
    func onAccountCheck(accountType: AccountType, predefinedAccountType: PredefinedAccountType?, coins: ((AccountType, PredefinedAccountType, RestoreRouter.ProceedMode) -> ()))
    func onCoinsSelect(coins: [Coin], accountType: AccountType?, predefinedAccountType: PredefinedAccountType?, settings: () -> ()?, finish: () -> ()?)
    func onSettingsConfirm(accountType: AccountType?, coins: [Coin]?, settings: [BlockchainSetting], success: (() -> ()))
}
