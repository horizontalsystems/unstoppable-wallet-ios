import MarketKit

class ReceiveTokenViewModel: IReceiveSelectorViewModel {
    private let fullCoin: FullCoin
    private let accountType: AccountType

    init(fullCoin: FullCoin, accountType: AccountType) {
        self.fullCoin = fullCoin
        self.accountType = accountType
    }

}

extension ReceiveTokenViewModel {

    var viewItems: [ReceiveSelectorViewModel.ViewItem] {
        let tokens = fullCoin.tokens.filter { accountType.supports(token: $0) }
        return tokens.map {
            ReceiveSelectorViewModel.ViewItem(uid: $0.blockchain.uid,
                    imageUrl: $0.blockchainType.imageUrl,
                    title: $0.blockchain.name,
                    subtitle: $0.blockchainType.description
            )
        }
    }

    func item(uid: String) -> Token? {
        fullCoin.tokens.first { $0.blockchain.uid == uid }
    }

    var title: String { "receive_network_select.title".localized }
    var topDescription: String { "receive_network_select.description".localized }
    var highlightedBottomDescription: String? { nil }
}
