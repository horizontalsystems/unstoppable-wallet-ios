class StellarReceiveAddressViewItemFactory: ReceiveAddressViewItemFactory {
    override func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        if let item = item as? StellarReceiveAddressService.StellarAssetReceiveAddress, !item.activated {
            return .init(
                title: "deposit.stellar.inactive_asset.title".localized,
                description: .init(text: "deposit.stellar.inactive_asset.description".localized(item.coinCode, item.coinCode), style: .warning),
                mode: .activateStellarAsset
            )
        }

        return super.popup(item: item)
    }
}
