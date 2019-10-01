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
                linked: item.account != nil,
                rightButtonState: rightButtonState
        )
    }

}
