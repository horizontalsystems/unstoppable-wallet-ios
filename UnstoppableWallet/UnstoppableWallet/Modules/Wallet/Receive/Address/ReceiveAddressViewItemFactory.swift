import Foundation

import Foundation

class ReceiveAddressViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = ReceiveAddressService.Item

    func viewItem(item: Item) -> ReceiveAddressModule.ViewItem {
        var sections = [[ReceiveAddressModule.Item]]()

        let text = (item.watchAccount ? "deposit.qr_code_description.watch" : "deposit.qr_code_description").localized(item.coinCode)
        let qrItem = ReceiveAddressModule.QrItem(
                address: item.address.address,
                text: text
        )
        sections.append([.qrItem(qrItem)])

        var viewItems = [ReceiveAddressModule.Item]()
        viewItems.append(.value(title: "deposit.address".localized, value: item.address.address, copyable: false))

        var title: String = "deposit.address_network".localized
        var value: String = ""
        if let derivation = item.token.type.derivation {
            title = "deposit.address_format".localized
            value = derivation.addressType + " (\(derivation.title))"
        } else if let addressType = item.token.type.bitcoinCashCoinType {
            title = "deposit.address_format".localized
            value = addressType.description + " (\(addressType.title))"
        } else {
            value = item.token.blockchain.name
        }
        if !item.isMainNet {
            value += " (TestNet)"
        }
        viewItems.append(.value(title: title, value: value, copyable: false))

        var popupViewItem: ReceiveAddressModule.PopupWarningItem?
        if let address = item.address as? ActivatedDepositAddress, !address.isActive {
            viewItems.append(
                    .infoValue(
                            title: "deposit.account".localized,
                            value: "deposit.not_active".localized,
                            infoTitle: "deposit.not_active.title".localized,
                            infoDescription: "deposit.not_active.tron_description".localized,
                            style: .yellow
                    )
            )

            popupViewItem = .init(
                    title: "deposit.not_active.title".localized,
                    description: .init(text: "deposit.not_active.tron_description".localized, style: .yellow),
                    doneButtonTitle: "button.i_understand".localized
            )
        }

        sections.append(viewItems)

        sections.append([.highlightedDescription(text: "deposit.warning".localized(item.coinCode), style: .yellow)])


        return .init(
                address: item.address.address,
                popup: popupViewItem,
                sections: sections
        )
    }

}
