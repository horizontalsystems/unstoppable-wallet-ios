import Foundation
import RxSwift
import RxRelay
import EthereumKit

class WatchAddressService {
    private let accountFactory: AccountFactory
    private let accountManager: IAccountManager
    private let coinManager: CoinManager
    private let walletManager: WalletManager
    private let addressService: AddressService
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(accountFactory: AccountFactory, accountManager: IAccountManager, coinManager: CoinManager, walletManager: WalletManager, addressService: AddressService) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.addressService = addressService

        subscribe(disposeBag, addressService.stateObservable) { [weak self] in self?.sync(addressState: $0) }
    }

    private func sync(addressState: AddressService.State) {
        switch addressState {
        case .success(let address):
            do {
                state = .ready(address: try EthereumKit.Address(hex: address.raw), domain: address.domain)
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
        guard case let .ready(address, domain) = state else {
            throw StateError.notReady
        }

        let account = accountFactory.watchAccount(address: address, domain: domain)
        accountManager.save(account: account)

        do {
            let platformCoins = try coinManager.platformCoins(coinTypes: [.ethereum, .binanceSmartChain, .polygon])
            let wallets = platformCoins.map { Wallet(platformCoin: $0, account: account) }

            walletManager.save(wallets: wallets)
        } catch {
            // do nothing
        }
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
