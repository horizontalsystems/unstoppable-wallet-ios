import Combine
import MarketKit

class TransactionFilterViewModel: ObservableObject {
    private let transactionsViewModel: TransactionsViewModel
    private let securityManager = Core.shared.securityManager
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
        scamFilterEnabled = transactionsViewModel.spamFilterEnabled
        resetEnabled = transactionsViewModel.filterChanged

        transactionsViewModel.$transactionFilter
            .sink { [weak self] filter in
                guard let self else { return }
                blockchain = filter.blockchain
                token = filter.token
                contact = filter.contact
                resetEnabled = filter.hasChanges || !transactionsViewModel.spamFilterEnabled
            }
            .store(in: &cancellables)

        transactionsViewModel.$spamFilterEnabled
            .sink { [weak self] enabled in
                guard let self else { return }
                scamFilterEnabled = enabled
                resetEnabled = transactionsViewModel.transactionFilter.hasChanges || !enabled
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
        securityManager.setSpamFilter(enabled: scamFilterEnabled)
    }

    func reset() {
        transactionsViewModel.transactionFilter.reset()
        securityManager.setSpamFilter(enabled: true)
    }
}
