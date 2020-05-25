class DerivationSettingsViewItemFactory {

    func sectionViewItem(item: DerivationSettingsItem) -> DerivationSettingSectionViewItem {
        DerivationSettingSectionViewItem(
                coinName: item.firstCoin.title,
                items: MnemonicDerivation.allCases.map { derivation in
                    DerivationSettingViewItem(
                            title: derivation.title,
                            subtitle: derivation.description(coinType: item.setting.coinType),
                            selected: derivation == item.setting.derivation
                    )
                }
        )
    }

}
