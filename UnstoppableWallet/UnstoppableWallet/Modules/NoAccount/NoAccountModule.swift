protocol INoAccountView: class {
    func set(viewItem: NoAccountModule.ViewItem)
    func show(error: Error)
    func showSuccess()
}

protocol INoAccountViewDelegate {
    func onLoad()
    func onTapCreate()
    func onTapRestore()
    func onTapClose()
}

protocol INoAccountInteractor {
    func createAccount(predefinedAccountType: PredefinedAccountType) throws -> Account
    func save(account: Account)
    func resetAddressFormatSettings()
}

protocol INoAccountRouter {
    func closeAndShowRestore(predefinedAccountType: PredefinedAccountType)
    func close()
}

class NoAccountModule {

    struct ViewItem {
        let coinTitle: String
        let coinCode: String
        let blockchainType: String?
        let accountTypeTitle: String
        let coinCodes: String
        let createEnabled: Bool
    }

}
