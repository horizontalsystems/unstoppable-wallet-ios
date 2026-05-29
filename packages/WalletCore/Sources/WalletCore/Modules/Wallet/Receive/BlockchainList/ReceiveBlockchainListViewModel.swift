import Combine
import Foundation
import MarketKit

class ReceiveBlockchainListViewModel: ObservableObject {
    private let fullCoin: FullCoin
    private let accountType: AccountType

    init(fullCoin: FullCoin, accountType: AccountType) {
        self.fullCoin = fullCoin
        self.accountType = accountType
    }
}

extension ReceiveBlockchainListViewModel {
    var viewItems: [ReceiveBlockchainListViewModel.ViewItem] {
        let tokens = fullCoin.tokens
            .filter { accountType.supports(token: $0) }
            .sorted(by: SortCriterion.blockchainList, context: TokenSortContext())

        return tokens.map {
            .init(
                uid: $0.blockchain.uid,
                imageUrl: $0.blockchainType.imageUrl,
                title: $0.blockchain.name,
                subtitle: $0.blockchainType.description
            )
        }
    }

    func item(uid: String) -> Token? {
        fullCoin.tokens.first { $0.blockchain.uid == uid }
    }
}

extension ReceiveBlockchainListViewModel {
    struct ViewItem: Hashable, Identifiable {
        let uid: String
        let imageUrl: String?
        let title: String
        let subtitle: String

        var id: String { uid }
    }
}
