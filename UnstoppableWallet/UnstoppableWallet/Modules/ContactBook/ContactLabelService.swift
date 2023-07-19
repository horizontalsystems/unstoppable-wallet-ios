import Foundation
import MarketKit
import RxSwift
import RxRelay

class ContactLabelService {
    private let disposeBag = DisposeBag()
    private let contactManager: ContactBookManager?
    private let blockchainType: BlockchainType

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    private(set) var state: State = .idle {
        didSet {
            if oldValue != state {
                stateRelay.accept(state)
            }
        }
    }

    private let queue = DispatchQueue(label: "\(AppConfig.label).contact-label-service", qos: .userInitiated)
    private var observedAddress: String = ""

    init(contactManager: ContactBookManager?, blockchainType: BlockchainType) {
        self.contactManager = contactManager
        self.blockchainType = blockchainType

        if let contactManager {
            subscribe(disposeBag, contactManager.stateObservable) { [weak self] _ in self?.sync() }
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

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
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
