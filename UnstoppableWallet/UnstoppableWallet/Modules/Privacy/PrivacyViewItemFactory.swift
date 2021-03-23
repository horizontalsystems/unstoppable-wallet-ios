class PrivacyViewItemFactory {

    func syncViewItems(items: [PrivacySyncItem]) -> [PrivacyViewItem] {
        items.map { item in
            PrivacyViewItem(iconName: item.coin.id, title: item.coin.title, value: item.setting.syncMode.title, changable: item.changeable)
        }
    }

}
