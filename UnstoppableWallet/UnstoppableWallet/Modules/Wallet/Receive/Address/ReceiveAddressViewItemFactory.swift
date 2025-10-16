import Foundation

class ReceiveAddressViewItemFactory: IReceiveAddressViewItemFactory {
    typealias Item = ReceiveAddress

    func viewItem(item: ReceiveAddress, amount: String?) -> ReceiveAddressModule.ViewItem {
        guard let item = item as? ReceiveAddressService.AssetReceiveAddress else {
            return .empty(address: item.raw)
        }

        var alertCardViewItem: AlertCardViewItem?

        if let caution = item.caution {
            alertCardViewItem = AlertCardViewItem(text: caution.text, type: caution.type == .error ? .critical : .caution, style: .inline)
        } else if item.watchAccount {
            alertCardViewItem = AlertCardViewItem(text: "deposit.warning.watch_account".localized, style: .inline)
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
            default:
                if item.token.blockchainType != .monero {
                    addressUri.parameters[.tokenUid] = item.token.type.id
                }
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
            let appValue = AppValue(token: item.token, value: decimalValue)
            amountString = appValue.formattedFull()
        }

        var active = true
        if let address = item.address as? ActivatedDepositAddress, !address.isActive {
            active = false
        }

        var assetActivated = true
        if let address = item.address as? StellarDepositAddress, !address.assetActivated {
            assetActivated = false
        }

        let notEmpty = item.usedAddresses?.contains { _, value in !value.isEmpty } ?? false
        return .init(
            copyValue: uri,
            qrItem: qrItem,
            amount: amountString,
            active: active,
            assetActivated: assetActivated,
            memo: nil,
            usedAddresses: notEmpty ? item.usedAddresses : nil,
            caution: alertCardViewItem
        )
    }

    func popup(item: Item) -> ReceiveAddressModule.PopupWarningItem? {
        guard let item = item as? ReceiveAddressService.AssetReceiveAddress else {
            return nil
        }

        if let address = item.address as? ActivatedDepositAddress, !address.isActive {
            return .init(
                title: "deposit.not_active.title".localized,
                description: .init(text: "deposit.not_active.tron_description".localized, style: .warning),
                mode: .done(title: "button.i_understand".localized)
            )
        }

        if let address = item.address as? StellarDepositAddress, !address.assetActivated {
            return .init(
                title: "deposit.stellar.inactive_asset.title".localized,
                description: .init(text: "deposit.stellar.inactive_asset.description".localized(item.coinCode, item.coinCode), style: .warning),
                mode: .activateStellarAsset
            )
        }

        return nil
    }

    func actions(item: Item) -> [ReceiveAddressModule.ActionType] {
        guard let item = item as? ReceiveAddressService.AssetReceiveAddress else {
            return [.copy, .share]
        }

        if item.watchAccount {
            return [.copy, .share]
        }
        return [.amount, .copy, .share]
    }
}
