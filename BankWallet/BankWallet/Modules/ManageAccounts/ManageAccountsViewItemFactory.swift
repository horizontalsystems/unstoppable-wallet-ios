class ManageAccountsViewItemFactory {

    func viewItem(item: ManageAccountItem, hasDerivationSettings: Bool) -> ManageAccountViewItem {
        var topButtonState: ManageAccountButtonState?

        if item.account == nil, item.predefinedAccountType.createSupported {
            topButtonState = .create
        } else if let account = item.account {
            topButtonState = !account.backedUp ? .backup : .show
        }

        let middleButtonState: ManageAccountButtonState? = item.predefinedAccountType == .standard && hasDerivationSettings ? .settings : nil

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
