import Foundation
import RxSwift
import RxRelay
import EthereumKit

class WatchAddressService {
    private let accountFactory: AccountFactory
    private let accountManager: IAccountManager
    private let addressService: AddressService
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(accountFactory: AccountFactory, accountManager: IAccountManager, addressService: AddressService) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.addressService = addressService

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                state = .ready(address: try EthereumKit.Address(hex: address.raw))
            } catch {
                state = .notReady
            }
        default:
            state = .notReady
        }
    }

}

extension WatchAddressService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func watch() throws {
        guard case .ready(let address) = state else {
            throw StateError.notReady
        }

        let account = accountFactory.watchAccount(address: address)
        accountManager.save(account: account)
    }

}

extension WatchAddressService {

    enum State {
        case ready(address: EthereumKit.Address)
        case notReady
    }

    enum StateError: Error {
        case notReady
    }

}
