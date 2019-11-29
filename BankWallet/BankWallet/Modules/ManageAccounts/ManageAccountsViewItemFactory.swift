class ManageAccountsViewItemFactory {

    func viewItem(item: ManageAccountItem) -> ManageAccountViewItem {
        let rightButtonState: ManageAccountRightButtonState

        if let account = item.account {
            rightButtonState = !account.backedUp ? .backup : .show
        } else {
            rightButtonState = .restore
        }

        return ManageAccountViewItem(
                title: item.predefinedAccountType.title,
                coinCodes: item.predefinedAccountType.coinCodes,
                highlighted: item.account != nil,
                leftButtonState: item.account == nil ? .create(enabled: item.predefinedAccountType.createSupported) : .delete,
                rightButtonState: rightButtonState
        )
    }

}
