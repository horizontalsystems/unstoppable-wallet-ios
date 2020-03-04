class RestoreSequenceFactory: IRestoreSequenceFactory {

    func onAccountCheck(accountType: AccountType, predefinedAccountType: PredefinedAccountType?, settings: (() -> ()), coins: ((AccountType, PredefinedAccountType) -> ())) {
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        if predefinedAccountType == .standard {
            settings()
        } else {
            coins(accountType, predefinedAccountType)
        }

    }

    func onSettingsConfirm(accountType: AccountType?, predefinedAccountType: PredefinedAccountType?, coins: ((AccountType, PredefinedAccountType) -> ())) {
        guard let accountType = accountType else {
            return
        }
        guard let predefinedAccountType = predefinedAccountType else {
            return
        }

        coins(accountType, predefinedAccountType)
    }

}
