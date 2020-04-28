class PrivacyViewItemFactory {

    func syncViewItems(items: [PrivacySyncItem]) -> [PrivacyViewItem] {
        items.map { item in
            PrivacyViewItem(iconName: item.coin.code, title: item.coin.title, value: item.setting.syncMode.title, changable: true)
        }
    }

    func syncSelectViewItems(currentSetting: PrivacySyncItem, all: [SyncMode]) -> [PrivacySyncSelectViewItem] {
        let selectedSettingName: String = currentSetting.setting.syncMode.title
        let allSettings = all.map { $0.title }

        return allSettings.enumerated().map { index, title in
            PrivacySyncSelectViewItem(title: title, selected: title == selectedSettingName, priority: index == 0 ? .recommended : .morePrivate)
        }
    }

}
