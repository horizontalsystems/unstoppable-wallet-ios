import Foundation

class CexDepositViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = CexDepositService.Item

    func viewItem(item: Item) -> ReceiveAddressModule.ViewItem {
        var sections = [[ReceiveAddressModule.Item]]()

        let qrItem = ReceiveAddressModule.QrItem(
                address: item.address,
                text: "deposit.qr_code_description".localized(item.coinCode)
        )
        sections.append([.qrItem(qrItem)])

        var viewItems = [ReceiveAddressModule.Item]()
        viewItems.append(.value(title: "cex_deposit.address".localized, value: item.address, copyable: false))

        if let network = item.networkName {
            viewItems.append(.value(title: "cex_deposit.network".localized, value: network, copyable: false))
        }

        var popupViewItem: ReceiveAddressModule.PopupWarningItem?
        if let memo = item.memo {
            viewItems.append(.value(title: "cex_deposit.memo".localized, value: memo, copyable: true))

            popupViewItem = .init(
                    title: "cex_deposit.memo_warning.title".localized,
                    description: .init(text: "cex_deposit.memo_warning.description".localized, style: .red),
                    doneButtonTitle: "button.i_understand".localized
            )
        }

        sections.append(viewItems)

        let text = (item.memo == nil ? "" : "\("cex_deposit.warning_memo".localized)\n\n") + "deposit.warning".localized(item.coinCode)
        let style = item.memo == nil ? HighlightedDescriptionBaseView.Style.yellow : .red

        sections.append([.highlightedDescription(text: text, style: style)])


        return .init(
                address: item.address,
                popup: popupViewItem,
                sections: sections
        )
    }

}
