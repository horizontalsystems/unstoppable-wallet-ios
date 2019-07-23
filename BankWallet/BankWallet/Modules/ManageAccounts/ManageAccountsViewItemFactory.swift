class ManageAccountsViewItemFactory {

    func viewItem(item: ManageAccountItem) -> ManageAccountViewItem {
        let state: ManageAccountViewItemState

        if let account = item.account {
            state = .linked(backedUp: account.backedUp)
        } else {
            state = .notLinked
        }

        return ManageAccountViewItem(
                title: item.predefinedAccountType.title,
                coinCodes: item.predefinedAccountType.coinCodes,
                state: state
        )
    }

}
