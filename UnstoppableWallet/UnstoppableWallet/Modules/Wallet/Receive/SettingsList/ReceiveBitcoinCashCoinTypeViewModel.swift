import MarketKit

class ReceiveBitcoinCashCoinTypeViewModel: ReceiveSettingsViewModel {
    override var viewItems: [ReceiveSettingsViewModel.ViewItem] {
        wallets.compactMap { wallet in
            guard let bitcoinCashCoinType = wallet.token.type.bitcoinCashCoinType else {
                return nil
            }

            return .init(
                uid: bitcoinCashCoinType.rawValue,
                title: bitcoinCashCoinType.description + bitcoinCashCoinType.recommended,
                subtitle: bitcoinCashCoinType.title.uppercased()
            )
        }
    }

    override func item(uid: String) -> Wallet? {
        wallets.first { wallet in
            wallet.token.type.bitcoinCashCoinType == BitcoinCashCoinType(rawValue: uid)
        }
    }

    override var title: String { "receive_address_format_select.title".localized }
    override var topDescription: String { "receive_address_format_select.description".localized }
    override var highlightedBottomDescription: String? { "receive_address_format_select.bitcoin_cash.bottom_description".localized }
}
