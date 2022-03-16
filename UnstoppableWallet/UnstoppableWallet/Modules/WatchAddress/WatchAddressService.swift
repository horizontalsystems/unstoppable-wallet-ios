import Foundation
import RxSwift
import RxRelay
import EthereumKit

class WatchAddressService {
    private let accountFactory: AccountFactory
    private let accountManager: AccountManager
    private let coinManager: CoinManager
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let addressService: AddressService
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(accountFactory: AccountFactory, accountManager: AccountManager, coinManager: CoinManager, walletManager: WalletManager, evmBlockchainManager: EvmBlockchainManager, addressService: AddressService) {
        self.accountFactory = accountFactory
        self.accountManager = accountManager
        self.coinManager = coinManager
        self.walletManager = walletManager
        self.evmBlockchainManager = evmBlockchainManager
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
            let evmBlockchains = evmBlockchainManager.allBlockchains

            for evmBlockchain in evmBlockchains {
                evmBlockchainManager.evmAccountManager(blockchain: evmBlockchain).markAutoEnable(account: account)
            }

            let platformCoins = try coinManager.platformCoins(coinTypes: evmBlockchains.map { $0.baseCoinType })
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
