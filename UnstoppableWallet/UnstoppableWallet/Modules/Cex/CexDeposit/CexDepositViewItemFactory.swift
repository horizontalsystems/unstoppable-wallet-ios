import Foundation

class CexDepositViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = CexDepositService.Item

    func viewItem(item: Item, amount _: String?) -> ReceiveAddressModule.ViewItem {
        var sections = [[ReceiveAddressModule.Item]]()

        let text = (item.memo == nil ? "" : "\("cex_deposit.warning_memo".localized)\n\n") + "deposit.warning".localized(item.coinCode)
        let style = item.memo == nil ? HighlightedDescriptionBaseView.Style.yellow : .red

        sections.append([.highlightedDescription(text: text, style: style)])

        var viewItems = [ReceiveAddressModule.Item]()
        let qrItem = ReceiveAddressModule.QrItem(
            address: item.address,
            uri: nil,
            networkName: item.networkName
        )
        viewItems.append(.qrItem(qrItem))

        if let memo = item.memo {
            viewItems.append(.memo(value: memo))
        }

        sections.append(viewItems)

        return .init(
            copyValue: item.address,
            sections: sections
        )
    }

    func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        item.memo.map { _ in
            .init(title: "cex_deposit.memo_warning.title".localized,
                  description: .init(text: "cex_deposit.memo_warning.description".localized, style: .red),
                  doneButtonTitle: "button.i_understand".localized
            )
        }
    }

    func actions(item _: Item) -> [ReceiveAddressModule.ActionType] {
        [.copy, .share]
    }
}
