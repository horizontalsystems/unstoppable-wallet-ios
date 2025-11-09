class TronReceiveAddressViewItemFactory: ReceiveAddressViewItemFactory {
    override func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        if let item = item as? TronReceiveAddressService.TronAssetReceiveAddress, !item.activated {
            return .init(
                title: "deposit.not_active.title".localized,
                description: .init(text: "deposit.not_active.tron_description".localized),
                mode: .done(title: "button.understood".localized)
            )
        }

        return super.popup(item: item)
    }
}
