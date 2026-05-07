import MarketKit

class ReceiveDerivationViewModel: ReceiveSettingsViewModel {
    override var viewItems: [ReceiveSettingsViewModel.ViewItem] {
        wallets.compactMap { wallet in
            guard let derivation = wallet.token.type.derivation else {
                return nil
            }

            return .init(
                uid: derivation.rawValue,
                title: derivation.addressType + derivation.recommended,
                subtitle: derivation.title
            )
        }
    }

    override func item(uid: String) -> Wallet? {
        wallets.first { wallet in
            wallet.token.type.derivation == MnemonicDerivation(rawValue: uid)
        }
    }

    override var title: String { "receive_address_format_select.title".localized }
    override var topDescription: String { "receive_address_format_select.description".localized }
    override var highlightedBottomDescription: String? { "receive_address_format_select.bitcoin.bottom_description".localized }
}
