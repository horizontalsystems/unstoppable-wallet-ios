import Combine
import MarketKit

class TransactionFilterViewModel: ObservableObject {
    private let transactionsViewModel: TransactionsViewModel
    private var cancellables = Set<AnyCancellable>()

    @Published var blockchain: Blockchain?
    @Published var token: Token?
    @Published var contact: Contact?

    @Published var scamFilterEnabled: Bool
    @Published var resetEnabled: Bool

    init(transactionsViewModel: TransactionsViewModel) {
        self.transactionsViewModel = transactionsViewModel

        blockchain = transactionsViewModel.transactionFilter.blockchain
        token = transactionsViewModel.transactionFilter.token
        contact = transactionsViewModel.transactionFilter.contact
        scamFilterEnabled = transactionsViewModel.transactionFilter.scamFilterEnabled
        resetEnabled = transactionsViewModel.transactionFilter.hasChanges

        transactionsViewModel.$transactionFilter
            .sink { [weak self] filter in
                self?.blockchain = filter.blockchain
                self?.token = filter.token
                self?.contact = filter.contact
                self?.scamFilterEnabled = filter.scamFilterEnabled
                self?.resetEnabled = filter.hasChanges
            }
            .store(in: &cancellables)
    }

    func set(blockchain: Blockchain?) {
        transactionsViewModel.transactionFilter.set(blockchain: blockchain)
    }

    func set(token: Token?) {
        transactionsViewModel.transactionFilter.set(token: token)
    }

    func set(contact: Contact?) {
        transactionsViewModel.transactionFilter.contact = contact
    }

    func set(scamFilterEnabled: Bool) {
        transactionsViewModel.transactionFilter.scamFilterEnabled = scamFilterEnabled
    }

    func reset() {
        transactionsViewModel.transactionFilter.reset()
    }
}
