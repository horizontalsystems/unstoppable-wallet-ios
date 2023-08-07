import MarketKit

class ReceiveDerivationViewModel: IReceiveSelectorViewModel {
    private let wallets: [Wallet]

    init(wallets: [Wallet]) {
        self.wallets = wallets
    }

}

extension ReceiveDerivationViewModel {

    var viewItems: [ReceiveSelectorViewModel.ViewItem] {
        wallets.compactMap { wallet in
            guard let derivation = wallet.configuredToken.coinSettings.derivation else {
                return nil
            }

            return ReceiveSelectorViewModel.ViewItem(
                    uid: derivation.rawValue,
                    imageUrl: nil,
                    title: derivation.addressType + (derivation.recommended ? "receive_address.recommended".localized : ""),
                    subtitle: derivation.title
            )
        }
    }

    func item(uid: String) -> Wallet? {
        wallets.first { wallet in
            wallet.configuredToken.coinSettings.derivation == MnemonicDerivation(rawValue: uid)
        }
    }

    var title: String { "receive_address_format_select.title".localized }
    var topDescription: String { "receive_address_format_select.description".localized }
    var highlightedBottomDescription: String? { "receive_address_format_select.bitcoin.bottom_description".localized }

}
