class BlockchainSettingsListViewItemFactory {

    func viewItems(settableCoins: [Coin], selectedCoins: [Coin], currentSettings: [BlockchainSetting]) -> [BlockchainSettingsListViewItem] {
        settableCoins.compactMap { coin in
            guard let currentSetting = (currentSettings.first { $0.coinType == coin.type }) else {
                return nil
            }

            var subtitle = ""
            if let derivation = currentSetting.derivation {
                subtitle += derivation.title
                subtitle += " | "
            }
            if let syncMode = currentSetting.syncMode {
                subtitle += syncMode.title
            }

            return BlockchainSettingsListViewItem(
                    title: "blockchain_settings.chain_title".localized(coin.title), 
                    subtitle: subtitle,
                    enabled: selectedCoins.contains { $0.type == coin.type }
            )
        }
    }

}
