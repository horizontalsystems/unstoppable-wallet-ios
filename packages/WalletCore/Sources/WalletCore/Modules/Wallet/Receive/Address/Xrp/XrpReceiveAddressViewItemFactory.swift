class XrpReceiveAddressViewItemFactory: ReceiveAddressViewItemFactory {
    override func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        // the popup offers activation, which a watch account cannot sign; the warning row itself stays
        if let item = item as? XrpReceiveAddressService.XrpAssetReceiveAddress, !item.activated, !item.watchAccount {
            return .init(
                title: "deposit.stellar.inactive_asset.title".localized,
                description: .init(text: "deposit.xrp.inactive_asset.description".localized(item.coinCode, item.coinCode)),
                mode: .activateXrpAsset
            )
        }

        return super.popup(item: item)
    }
}
