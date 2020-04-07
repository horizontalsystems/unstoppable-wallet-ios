class RestoreAccountTypeHandler {
    private let router: IRestoreAccountTypeRouter
    private let restoreManager: IRestoreManager
    let selectCoins: Bool

    init(router: IRestoreAccountTypeRouter, restoreManager: IRestoreManager, selectCoins: Bool) {
        self.router = router
        self.restoreManager = restoreManager
        self.selectCoins = selectCoins
    }

}

extension RestoreAccountTypeHandler: IRestoreAccountTypeHandler {

    func handle(accountType: AccountType) {
        if selectCoins {
            router.showSelectCoins(accountType: accountType)
        } else {
            restoreManager.createAccount(accountType: accountType, coins: [])
            router.dismiss()
        }
    }

    func handleCancel() {
        router.dismiss()
    }

}
