import Foundation

class ReceiveAddressViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = ReceiveAddressService.Item

    func viewItem(item: Item, amount: String?) -> ReceiveAddressModule.ViewItem {
        var sections = [[ReceiveAddressModule.Item]]()

        sections.append([.highlightedDescription(text: "deposit.warning".localized(item.coinCode), style: .yellow)])

        var viewItems = [ReceiveAddressModule.Item]()

        var networkName = ""
        if let derivation = item.token.type.derivation {
            networkName = "deposit.address_format".localized + ": "
            networkName += derivation.addressType + " (\(derivation.title))"
        } else if let addressType = item.token.type.bitcoinCashCoinType {
            networkName = "deposit.address_format".localized + ": "
            networkName += addressType.description + " (\(addressType.title))"
        } else {
            networkName = "deposit.address_network".localized + ": "
            networkName += item.token.blockchain.name
        }
        if !item.isMainNet {
            networkName += " (TestNet)"
        }

        var uri = item.address.address
        if let amount {
            let parser = AddressUriParser(blockchainType: item.token.blockchainType, tokenType: item.token.type)
            var addressUri = AddressUri(scheme: item.token.blockchainType.uriScheme ?? "")
            addressUri.address = uri

            addressUri.parameters[AddressUri.Field.amountField(blockchainType: item.token.blockchainType)] = amount
            addressUri.parameters[.blockchainUid] = item.token.blockchainType.uid
            addressUri.parameters[.tokenUid] = item.token.type.id

            uri = parser.uri(addressUri)
        }
        let qrItem = ReceiveAddressModule.QrItem(
            address: item.address.address,
            uri: uri,
            networkName: networkName
        )
        viewItems.append(.qrItem(qrItem))

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
        }

        sections.append(viewItems)

        return .init(
            copyValue: uri,
            sections: sections
        )
    }

    func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        if let address = item.address as? ActivatedDepositAddress, !address.isActive {
            return .init(
                title: "deposit.not_active.title".localized,
                description: .init(text: "deposit.not_active.tron_description".localized, style: .yellow),
                doneButtonTitle: "button.i_understand".localized
            )
        }
        return nil
    }

    func actions(item: Item) -> [ReceiveAddressModule.ActionType] {
        if item.watchAccount {
            return [.copy, .share]
        }
        return [.amount, .copy, .share]
    }
}
