import Combine
import MarketKit

class TransactionContactSelectViewModel: ObservableObject {
    static let allowedBlockchainUids = EvmBlockchainManager.blockchainTypes.map(\.uid) + [
        BlockchainType.tron.uid,
        BlockchainType.ton.uid,
        BlockchainType.stellar.uid,
        BlockchainType.xrp.uid,
        BlockchainType.near.uid,
        BlockchainType.zcash.uid,
    ]
    private var cancellables = Set<AnyCancellable>()

    private let transactionFilterViewModel: TransactionFilterViewModel

    var contacts: [Contact] = []

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        self.transactionFilterViewModel = transactionFilterViewModel

        subscribe(&cancellables, Core.shared.contactManager.statePublisher) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        let allContacts = Core.shared.contactManager.all ?? []
        var suitableBlockchainUids = Self.allowedBlockchainUids

        if let selectedBlockchain = transactionFilterViewModel.blockchain {
            guard suitableBlockchainUids.contains(selectedBlockchain.type.uid) else {
                contacts = []
                return
            }
            suitableBlockchainUids = [selectedBlockchain.type.uid]
        }

        contacts = allContacts.filter { $0.hasOne(of: suitableBlockchainUids) }
    }

    var allowedBlockchainsForContact: [Blockchain] {
        (try? Core.shared.marketKit.blockchains(uids: Self.allowedBlockchainUids)) ?? []
    }

    var currentContact: Contact? {
        transactionFilterViewModel.contact
    }

    func set(currentContact: Contact?) {
        transactionFilterViewModel.set(contact: currentContact)
    }
}
