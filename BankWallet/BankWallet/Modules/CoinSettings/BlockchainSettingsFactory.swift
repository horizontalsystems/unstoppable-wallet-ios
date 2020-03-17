class BlockchainSettingsFactory {

    func settings(coinType: CoinType, originalSettings: BlockchainSetting?) -> BlockchainSetting {
        BlockchainSetting(coinType: coinType, derivation: originalSettings?.derivation, syncMode: originalSettings?.syncMode == .new ? nil : originalSettings?.syncMode)
    }

}
