class ManageAccountsViewItemFactory {

    func viewItem(item: ManageAccountItem, hasAddressFormatSettings: Bool) -> ManageAccountViewItem {
        let topButtonState: ManageAccountButtonState? = item.predefinedAccountType == .standard && hasAddressFormatSettings ? .settings : nil

        var middleButtonState: ManageAccountButtonState?

        if item.account == nil, item.predefinedAccountType.createSupported {
            middleButtonState = .create
        } else if let account = item.account {
            middleButtonState = !account.backedUp ? .backup : .show
        }

        let bottomButtonState: ManageAccountButtonState

        if item.account != nil {
            bottomButtonState = .delete
        } else {
            bottomButtonState = .restore
        }

        return ManageAccountViewItem(
                title: item.predefinedAccountType.title,
                coinCodes: item.predefinedAccountType.coinCodes,
                highlighted: item.account != nil,
                topButtonState: topButtonState,
                middleButtonState: middleButtonState,
                bottomButtonState: bottomButtonState
        )
    }

}
