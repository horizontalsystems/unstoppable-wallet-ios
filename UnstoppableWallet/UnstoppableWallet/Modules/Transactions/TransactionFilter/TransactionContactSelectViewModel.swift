import Combine
import MarketKit
import RxSwift

class TransactionContactSelectViewModel: ObservableObject {
    static let allowedBlockchainUids = EvmBlockchainManager.blockchainTypes.map(\.uid) + [
        BlockchainType.tron.uid,
        BlockchainType.ton.uid,
        BlockchainType.zcash.uid,
    ]
    private let disposeBag = DisposeBag()

    private let transactionFilterViewModel: TransactionFilterViewModel

    var contacts: [Contact] = []

    init(transactionFilterViewModel: TransactionFilterViewModel) {
        self.transactionFilterViewModel = transactionFilterViewModel

        subscribe(disposeBag, App.shared.contactManager.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        let allContacts = App.shared.contactManager.all ?? []
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
        (try? App.shared.marketKit.blockchains(uids: Self.allowedBlockchainUids)) ?? []
    }

    var currentContact: Contact? {
        transactionFilterViewModel.contact
    }

    func set(currentContact: Contact?) {
        transactionFilterViewModel.set(contact: currentContact)
    }
}
