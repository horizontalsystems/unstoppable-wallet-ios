import Combine
import MarketKit

class TransactionFilterViewModel: ObservableObject {
    private let service: TransactionFilterService
    private var cancellables = Set<AnyCancellable>()

    @Published var blockchain: Blockchain?
    @Published var token: Token?
    @Published var contact: Contact?
    @Published var scamFilterEnabled: Bool
    @Published var resetEnabled: Bool

    init(service: TransactionFilterService) {
        self.service = service

        blockchain = service.transactionFilter.blockchain
        token = service.transactionFilter.token
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

    var blockchains: [Blockchain] {
        service.allBlockchains
    }

    var tokens: [Token] {
        service.allTokens
    }

    var contacts: [Contact] {
        service.allContacts.by(blockchainUid: service.transactionFilter.blockchain?.uid)
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
