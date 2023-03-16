import Foundation
import MarketKit
import RxSwift
import RxRelay

class TransactionsContactLabelService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactBookManager?

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(contactManager: ContactBookManager?) {
        self.contactManager = contactManager

        if let contactManager {
            subscribe(disposeBag, contactManager.stateObservable) { [weak self] _ in self?.sync() }
        }
    }

    private func sync() {
        guard contactManager?.state.data != nil else {
            state = .idle
            return
        }
        state = .updatedBook
    }

}

extension TransactionsContactLabelService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func contactData(for address: String, blockchainType: BlockchainType) -> ContactData {
        if let name = contactManager?.name(blockchainType: blockchainType, address: address) {
            return ContactData(name: name, contactAddress: nil)
        }
        return ContactData(name: nil, contactAddress: ContactAddress(blockchainUid: blockchainType.uid, address: address))
    }

}

extension TransactionsContactLabelService {

    enum State {
        case idle
        case updatedBook
    }

    struct ContactData {
        let name: String?
        let contactAddress: ContactAddress?
    }

}
