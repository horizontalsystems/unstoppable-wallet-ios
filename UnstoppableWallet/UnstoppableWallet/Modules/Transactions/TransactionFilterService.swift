import Combine
import HsExtensions
import MarketKit

class TransactionFilterService {
    static let allowedBlockchainForContacts: [BlockchainType] =
        EvmBlockchainManager.blockchainTypes

    @DistinctPublished var transactionFilter = TransactionFilter()
    var allBlockchains = [Blockchain]()
    var allTokens = [Token]()
    var allContacts = [Contact]()

    func handle(wallets: [Wallet]) {
        allBlockchains = Array(Set(wallets.map(\.token.blockchain)))
            .sorted { $0.type.order < $1.type.order }

        allTokens = wallets.map(\.token)
            .sorted { lhsToken, rhsToken in
                let lhsName = lhsToken.coin.name.lowercased()
                let rhsName = rhsToken.coin.name.lowercased()

                if lhsName != rhsName {
                    return lhsName < rhsName
                }

                return lhsToken.badge ?? "" < rhsToken.badge ?? ""
            }

        var newFilter = transactionFilter

        if let blockchain = newFilter.blockchain, !allBlockchains.contains(blockchain) {
            newFilter.set(blockchain: nil)
        }

        if let token = newFilter.token, !allTokens.contains(token) {
            newFilter.set(token: nil)
        }

        handleContacts(filter: newFilter)

        if let contact = newFilter.contact, !allContacts.contains(contact) {
            newFilter.set(contact: nil)
        }

        transactionFilter = newFilter
    }

    var allowedBlockchainForContacts: [Blockchain] {
        do {
            return try App.shared.marketKit.blockchains(uids: Self.allowedBlockchainForContacts.map(\.uid))
        } catch {
            return []
        }
    }

    func handleContacts(filter: TransactionFilter? = nil) {
        allContacts = (App
            .shared
            .contactManager
            .all ?? [])
            .filter { // filter only contacts with allowed addresses(blockchains)
                $0.addresses.contains {
                    TransactionFilterService
                        .allowedBlockchainForContacts
                        .map(\.uid)
                        .contains($0.blockchainUid)
                }
            }
    }
}
