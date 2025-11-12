import Foundation

class ReceiveAddressViewItemFactory {
    typealias Item = ReceiveAddress

    func viewItem(item: Item, amount: String?) -> ReceiveAddressModule.ViewItem {
        guard let item = item as? BaseReceiveAddressService.AssetReceiveAddress else {
            return .empty(address: item.raw)
        }

        let uri = uri(item: item, amount: amount)

        let qrItem = ReceiveAddressModule.QrItem(
            address: item.address.address,
            uri: uri,
            networkName: networkName(item: item)
        )

        var amountString: String?
        if let amount, let decimalValue = Decimal(string: amount) {
            let appValue = AppValue(token: item.token, value: decimalValue)
            amountString = appValue.formattedFull()
        }

        return .init(
            copyValue: uri,
            highlightedDescription: description(item: item),
            qrItem: qrItem,
            amount: amountString,
        )
    }

    func description(item: BaseReceiveAddressService.AssetReceiveAddress) -> ReceiveAddressModule.HighlightedDescription? {
        if item.watchAccount {
            return .init(
                text: "deposit.warning.watch_account".localized,
                style: .yellow
            )
        }

        return nil
    }

    func networkName(item: BaseReceiveAddressService.AssetReceiveAddress) -> String {
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

        return networkName
    }

    func uri(item: BaseReceiveAddressService.AssetReceiveAddress, amount: String?) -> String {
        var uri = item.address.address
        if let amount {
            let parser = AddressUriParser(blockchainType: item.token.blockchainType, tokenType: item.token.type)
            var addressUri = AddressUri(scheme: item.token.blockchainType.uriScheme ?? "")
            addressUri.address = uri

            addressUri.parameters[AddressUri.Field.amountField(blockchainType: item.token.blockchainType)] = amount
            addressUri.parameters[.blockchainUid] = item.token.blockchainType.uid
            switch item.token.type {
            case .addressType, .derived: ()
            default:
                if item.token.blockchainType != .monero {
                    addressUri.parameters[.tokenUid] = item.token.type.id
                }
            }

            uri = parser.uri(addressUri)
        }
        return uri
    }

    func popup(item _: Item) -> ReceiveAddressModule.PopupWarningItem? {
        nil
    }

    func actions(item: Item) -> [ReceiveAddressModule.ActionType] {
        guard let item = item as? BaseReceiveAddressService.AssetReceiveAddress else {
            return [.copy, .share]
        }

        if item.watchAccount {
            return [.copy, .share]
        }
        return [.amount, .copy, .share]
    }
}
