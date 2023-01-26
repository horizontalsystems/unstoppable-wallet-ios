import Foundation
import RxSwift
import RxRelay
import EvmKit

class WatchEvmAddressService {
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(addressService: AddressService) {
        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                state = .ready(address: try EvmKit.Address(hex: address.raw), domain: address.domain)
            } catch {
                state = .notReady
            }
        default:
            state = .notReady
        }
    }

}

extension WatchEvmAddressService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func resolve() -> AccountType? {
        switch state {
        case let .ready(address, _): return AccountType.evmAddress(address: address)
        case .notReady: return nil
        }
    }

}

extension WatchEvmAddressService {

    enum State {
        case ready(address: EvmKit.Address, domain: String?)
        case notReady

        var watchEnabled: Bool {
            switch self {
            case .ready: return true
            case .notReady: return false
            }
        }

        var domain: String? {
            switch self {
            case .ready(_, let domain): return domain
            case .notReady: return nil
            }
        }

    }

}
