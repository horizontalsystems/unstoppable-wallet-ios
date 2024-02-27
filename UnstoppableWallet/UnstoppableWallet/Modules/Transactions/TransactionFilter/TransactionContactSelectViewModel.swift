import Combine
import MarketKit

class TransactionContactSelectViewModel: ObservableObject {
    private let transactionFilterViewModel: TransactionFilterViewModel

    let contacts: [Contact]

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        self.transactionFilterViewModel = transactionFilterViewModel

        contacts = [] // todo
    }

    var allowedBlockchainsForContact: [Blockchain] {
        [] // todo
    }

    var currentContact: Contact? {
        transactionFilterViewModel.contact
    }

    func set(currentContact: Contact?) {
        transactionFilterViewModel.set(contact: currentContact)
    }
}
