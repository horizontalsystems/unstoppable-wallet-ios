import Combine
import Foundation
import MarketKit

class TransactionsContactLabelService {
    private var cancellables = Set<AnyCancellable>()
    private let contactManager: ContactBookManager?

    private let stateSubject = CurrentValueSubject<State, Never>(.idle)
    private(set) var state: State = .idle {
        didSet {
            stateSubject.send(state)
        }
    }

    init(contactManager: ContactBookManager?) {
        self.contactManager = contactManager

        if let contactManager {
            contactManager.statePublisher
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink { [weak self] _ in self?.sync() }
                .store(in: &cancellables)
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
    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
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
