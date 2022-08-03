import Foundation
import RxSwift
import RxRelay
import EthereumKit
import MarketKit

class WatchAddressService {
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    let defaultName: String

    private let nameRelay = PublishRelay<String>()
    private(set) var name: String = "" {
        didSet {
            nameRelay.accept(name)
        }
    }

    init(accountFactory: AccountFactory, accountManager: AccountManager, addressService: AddressService) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager

        defaultName = accountFactory.nextWatchAccountName

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                state = .ready(address: try EthereumKit.Address(hex: address.raw), domain: address.domain)

                if let domain = address.domain, name.trimmingCharacters(in: .whitespaces).isEmpty {
                    name = domain
                }
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

    var nameObservable: Observable<String> {
        nameRelay.asObservable()
    }

    func set(name: String) {
        self.name = name
    }

    func watch() throws {
        guard case let .ready(address, domain) = state else {
            throw StateError.notReady
        }

        let name = name.trimmingCharacters(in: .whitespaces).isEmpty ? defaultName : name
        let account = accountFactory.watchAccount(name: name, address: address, domain: domain)
        accountManager.save(account: account)
    }

}

extension WatchAddressService {

    enum State {
        case ready(address: EthereumKit.Address, domain: String?)
        case notReady
    }

    enum StateError: Error {
        case notReady
    }

}
