import Foundation

class CexDepositViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = CexDepositService.Item

    func viewItem(item: Item, amount _: String?) -> ReceiveAddressModule.ViewItem {
        let text = (item.memo == nil ? "" : "\("cex_deposit.warning_memo".localized)") + "deposit.warning".localized
        let style = item.memo == nil ? HighlightedDescriptionBaseView.Style.yellow : .red

        let description = ReceiveAddressModule.HighlightedDescription(
            text: text,
            style: style
        )

        let qrItem = ReceiveAddressModule.QrItem(
            address: item.address,
            uri: nil,
            networkName: item.networkName
        )

        return .init(
            copyValue: item.address,
            highlightedDescription: description,
            qrItem: qrItem,
            amount: nil,
            active: true,
            memo: item.memo,
            usedAddresses: nil
        )
    }

    func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        item.memo.map { _ in
            .init(title: "cex_deposit.memo_warning.title".localized,
                  description: .init(text: "cex_deposit.memo_warning.description".localized, style: .red),
                  doneButtonTitle: "button.i_understand".localized)
        }
    }

    func actions(item _: Item) -> [ReceiveAddressModule.ActionType] {
        [.copy, .share]
    }
}
