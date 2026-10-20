import Combine
import Foundation
import MarketKit

class ContactLabelService {
    private var cancellables = Set<AnyCancellable>()
    private let contactManager: ContactBookManager?
    private let blockchainType: BlockchainType

    private let stateSubject = CurrentValueSubject<State, Never>(.idle)
    private(set) var state: State = .idle {
        didSet {
            if oldValue != state {
                stateSubject.send(state)
            }
        }
    }

    private let queue = DispatchQueue(label: "\(AppConfig.label).contact-label-service", qos: .userInitiated)
    private var observedAddress: String = ""

    init(contactManager: ContactBookManager?, blockchainType: BlockchainType) {
        self.contactManager = contactManager
        self.blockchainType = blockchainType

        if let contactManager {
            contactManager.statePublisher
                .receive(on: DispatchQueue.global(qos: .userInitiated))
                .sink { [weak self] _ in self?.sync() }
                .store(in: &cancellables)
        }
    }

    private func sync() {
        queue.sync {
            guard contactManager?.state.data != nil, !observedAddress.isEmpty else {
                state = .idle
                return
            }

            if contactManager?.name(blockchainType: blockchainType, address: observedAddress) != nil {
                state = .exist
            } else {
                state = .notExist
            }
        }
    }
}

extension ContactLabelService {
    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func contactData(for address: String) -> ContactData {
        queue.sync {
            observedAddress = address
        }

        if let name = contactManager?.name(blockchainType: blockchainType, address: address) {
            return ContactData(name: name, contactAddress: nil)
        }
        return ContactData(name: nil, contactAddress: ContactAddress(blockchainUid: blockchainType.uid, address: address))
    }
}

extension ContactLabelService {
    enum State {
        case idle
        case exist
        case notExist
    }

    struct ContactData {
        let name: String?
        let contactAddress: ContactAddress?
    }
}
