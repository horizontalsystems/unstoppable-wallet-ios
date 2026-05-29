import MoneroKit

class MoneroWatchWalletParser {
    func parseAndValidate(address: Address, viewKey: String, forceRequiredFields: Bool) -> (WatchViewModel.State, CautionState) {
        var validViewKey: String?

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

        if let validViewKey {
            let accountType = AccountType.moneroWatchAccount(address: address.raw, viewKey: validViewKey)
            return (.ready(accountType: accountType), viewKeyCautionState)
        } else {
            return (.incomplete, viewKeyCautionState)
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
