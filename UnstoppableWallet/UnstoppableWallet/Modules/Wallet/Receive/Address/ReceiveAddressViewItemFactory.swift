import Foundation

class ReceiveAddressViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = ReceiveAddressService.Item

    func viewItem(item: Item, amount: String?) -> ReceiveAddressModule.ViewItem {
        var description: ReceiveAddressModule.HighlightedDescription?
        if item.watchAccount {
            description = .init(
                text: "deposit.warning.watch_account".localized,
                style: .yellow
            )
        }

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
            switch item.token.type {
            case .addressType, .derived: ()
            default: addressUri.parameters[.tokenUid] = item.token.type.id
            }

            uri = parser.uri(addressUri)
        }
        let qrItem = ReceiveAddressModule.QrItem(
            address: item.address.address,
            uri: uri,
            networkName: networkName
        )
        var amountString: String?
        if let amount, let decimalValue = Decimal(string: amount) {
            let coinValue = CoinValue(kind: .token(token: item.token), value: decimalValue)
            amountString = coinValue.formattedFull
        }

        var active = true
        if let address = item.address as? ActivatedDepositAddress, !address.isActive {
            active = false
        }

        let notEmpty = item.usedAddresses?.contains { _, value in !value.isEmpty } ?? false
        return .init(
            copyValue: uri,
            highlightedDescription: description,
            qrItem: qrItem,
            amount: amountString,
            active: active,
            memo: nil,
            usedAddresses: notEmpty ? item.usedAddresses : nil
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
