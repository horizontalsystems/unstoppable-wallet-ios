import MarketKit

class ReceiveBitcoinCashCoinTypeViewModel: IReceiveSelectorViewModel {
    private let wallets: [Wallet]

    init(wallets: [Wallet]) {
        self.wallets = wallets
    }

}

extension ReceiveBitcoinCashCoinTypeViewModel {

    var viewItems: [ReceiveSelectorViewModel.ViewItem] {
        wallets.compactMap { wallet in
            guard let bitcoinCashCoinType = wallet.token.type.bitcoinCashCoinType else {
                return nil
            }

            return ReceiveSelectorViewModel.ViewItem(
                    uid: bitcoinCashCoinType.rawValue,
                    imageUrl: nil,
                    title: bitcoinCashCoinType.description + bitcoinCashCoinType.recommended,
                    subtitle: bitcoinCashCoinType.title.uppercased()
            )
        }
    }

    func item(uid: String) -> Wallet? {
        wallets.first { wallet in
            wallet.token.type.bitcoinCashCoinType == BitcoinCashCoinType(rawValue: uid)
        }
    }

    var title: String { "receive_address_format_select.title".localized }
    var topDescription: String { "receive_address_format_select.description".localized }
    var highlightedBottomDescription: String? { "receive_address_format_select.bitcoin_cash.bottom_description".localized }

}
