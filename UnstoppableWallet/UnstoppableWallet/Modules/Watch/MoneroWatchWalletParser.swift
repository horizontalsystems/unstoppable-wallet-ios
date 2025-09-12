import MoneroKit

class MoneroWatchWalletParser {
    func parseAndValidate(address: Address, viewKey: String, height: String, forceRequiredFields: Bool) -> (WatchViewModel.State, CautionState, CautionState) {
        var validViewKey: String?
        var validHeight: Int?

        let viewKeyCautionState: CautionState
        if viewKey.isEmpty {
            if forceRequiredFields {
                viewKeyCautionState = CautionState.caution(.init(text: "watch_address.view_key.error.required".localized, type: .error))
            } else {
                viewKeyCautionState = .none
            }
        } else {
            let isValidViewKey = MoneroKit.Kit.isValid(
                viewKey: viewKey,
                address: address.raw,
                isViewKey: true,
                networkType: .mainnet
            )

            if isValidViewKey {
                validViewKey = viewKey
                viewKeyCautionState = .none
            } else {
                viewKeyCautionState = .caution(.init(text: "watch_address.view_key.error.invalid".localized, type: .error))
            }
        }

        let heightCautionState: CautionState
        if height.isEmpty {
            heightCautionState = .none
        } else {
            let parsedHeight = Int(height) ?? 0
            let maxHeight = MoneroKit.RestoreHeight.maximumEstimatedHeight()

            if parsedHeight > maxHeight || String(parsedHeight) != height {
                heightCautionState = .caution(.init(text: "watch_address.birthday_height.error.invalid".localized, type: .error))
            } else {
                validHeight = parsedHeight
                heightCautionState = .none
            }
        }

        if let validViewKey {
            if height.isEmpty || validHeight != nil {
                let accountType = AccountType.moneroWatchAccount(address: address.raw, viewKey: validViewKey, restoreHeight: validHeight ?? 1)
                return (.ready(accountType: accountType), viewKeyCautionState, heightCautionState)
            } else {
                return (.incomplete, viewKeyCautionState, heightCautionState)
            }
        } else {
            return (.incomplete, viewKeyCautionState, heightCautionState)
        }
    }

    func parse(uri: AddressUri) -> (Address, String, String)? {
        guard uri.scheme == "monero_wallet", MoneroKit.Kit.isValid(address: uri.address, networkType: MoneroAdapter.networkType) else {
            return nil
        }

        let address = Address(raw: uri.address, domain: nil, blockchainType: .monero)
        let viewKey = uri.unhandledParameters["view_key"] ?? ""
        let birthdayHeight = uri.unhandledParameters["height"].map { String(Int($0) ?? 0) } ?? ""

        return (address, viewKey, birthdayHeight)
    }
}
