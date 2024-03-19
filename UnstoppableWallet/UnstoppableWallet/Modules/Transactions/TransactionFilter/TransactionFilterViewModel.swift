import Combine
import MarketKit

class TransactionFilterViewModel: ObservableObject {
    private let service: TransactionsService
    private var cancellables = Set<AnyCancellable>()

    @Published var blockchain: Blockchain?
    @Published var token: Token?
    @Published var contact: Contact?

    @Published var scamFilterEnabled: Bool
    @Published var resetEnabled: Bool

    init(service: TransactionsService) {
        self.service = service

        blockchain = service.transactionFilter.blockchain
        token = service.transactionFilter.token
        contact = service.transactionFilter.contact
        scamFilterEnabled = service.transactionFilter.scamFilterEnabled
        resetEnabled = service.transactionFilter.hasChanges

        service.$transactionFilter
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
        var newFilter = service.transactionFilter
        newFilter.set(blockchain: blockchain)
        service.transactionFilter = newFilter
    }

    func set(token: Token?) {
        var newFilter = service.transactionFilter
        newFilter.set(token: token)
        service.transactionFilter = newFilter
    }

    func set(contact: Contact?) {
        var newFilter = service.transactionFilter
        newFilter.set(contact: contact)
        service.transactionFilter = newFilter
    }

    func set(scamFilterEnabled: Bool) {
        var newFilter = service.transactionFilter
        newFilter.scamFilterEnabled = scamFilterEnabled
        service.transactionFilter = newFilter
    }

    func reset() {
        var newFilter = service.transactionFilter
        newFilter.reset()
        service.transactionFilter = newFilter
    }
}
