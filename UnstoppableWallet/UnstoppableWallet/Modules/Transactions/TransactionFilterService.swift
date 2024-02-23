import Combine
import HsExtensions
import MarketKit

class TransactionFilterService {
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

    func handleContacts(filter: TransactionFilter?) {
        allContacts = App.shared.contactManager.contacts(blockchainUid: (filter ?? transactionFilter).blockchain?.uid)
    }
}
