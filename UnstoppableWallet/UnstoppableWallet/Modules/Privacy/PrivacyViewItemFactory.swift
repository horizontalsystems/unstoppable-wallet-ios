class PrivacyViewItemFactory {

    func syncViewItems(items: [PrivacySyncItem]) -> [PrivacyViewItem] {
        items.map { item in
            PrivacyViewItem(iconName: item.platformCoin.coinType.id, title: item.platformCoin.coin.name, value: item.setting.syncMode.title, changeable: item.changeable)
        }
    }

}
