protocol IUnlinkView: class {
    func set(accountTypeTitle: String)
    func set(viewItems: [UnlinkModule.ViewItem])
    func set(deleteButtonEnabled: Bool)
    func showSuccess()
}

protocol IUnlinkViewDelegate {
    func onLoad()
    func onTapViewItem(index: Int)
    func onTapDelete()
    func onTapClose()
}

protocol IUnlinkInteractor {
    func delete(account: Account)
}

protocol IUnlinkRouter {
    func close()
}

class UnlinkModule {

    struct ViewItem {
        let type: ItemType
        var checked: Bool

        init(type: ItemType) {
            self.type = type
            checked = false
        }
    }

    enum ItemType {
        case deleteAccount(accountTypeTitle: String)
        case disableCoins(coinCodes: String)
        case loseAccess
    }

}
