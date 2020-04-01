class DerivationSettingsViewItemFactory {

    func sectionViewItem(coin: Coin, selectedCoins: [Coin], selectedSetting: MnemonicDerivation, allSettings: [MnemonicDerivation]) -> DerivationSettingSectionViewItem {
        let enabled = selectedCoins.contains(coin)

        return DerivationSettingSectionViewItem(coinName: coin.title, enabled: enabled, items: allSettings.map {
            rowViewItem(derivation: $0, selectedDerivation: selectedSetting)
        })
    }

    private func rowViewItem(derivation: MnemonicDerivation, selectedDerivation: MnemonicDerivation) -> DerivationSettingViewItem {
        DerivationSettingViewItem(
                title: derivation.title,
                subtitle: derivation.description,
                selected: derivation == selectedDerivation
        )
    }

}
