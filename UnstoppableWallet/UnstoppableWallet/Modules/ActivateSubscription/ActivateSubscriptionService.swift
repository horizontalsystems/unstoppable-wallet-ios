import Foundation
import Combine
import EvmKit
import MarketKit
import HsToolKit
import HsExtensions

class ActivateSubscriptionService {
    private let marketKit: MarketKit.Kit
    private let subscriptionManager: SubscriptionManager
    private let accountManager: AccountManager
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .loading
    @PostPublished private(set) var activationState: ActivationState = .ready

    private let activatedSubject = PassthroughSubject<Void, Never>()
    private let activationErrorSubject = PassthroughSubject<Error, Never>()

    init(marketKit: MarketKit.Kit, subscriptionManager: SubscriptionManager, accountManager: AccountManager) {
        self.marketKit = marketKit
        self.subscriptionManager = subscriptionManager
        self.accountManager = accountManager

        fetchSubscriptions()
    }

    private func fetchSubscriptions() {
        let addressItems: [AddressItem] = accountManager.accounts.compactMap { account in
            guard let address = account.type.evmAddress(chain: App.shared.evmBlockchainManager.chain(blockchainType: .ethereum)) else {
                return nil
            }

            return AddressItem(account: account, address: address)
        }

        guard !addressItems.isEmpty else {
            state = .noSubscriptions
            return
        }

        state = .loading

        let addresses = addressItems.map { $0.address.hex }

        Task { [weak self, marketKit] in
            do {
                let subscriptions = try await marketKit.subscriptions(addresses: addresses)
                self?.handle(subscriptions: subscriptions, addressItems: addressItems)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func handle(subscriptions: [ProSubscription], addressItems: [AddressItem]) {
        let address = subscriptions.sorted { lhs, rhs in lhs.deadline > rhs.deadline }.first?.address

        guard let address else {
            state = .noSubscriptions
            return
        }

        let addressItem = addressItems.first { addressItem in
            addressItem.address.hex.caseInsensitiveCompare(address) == .orderedSame
        }

        guard let addressItem else {
            state = .noSubscriptions
            return
        }

        Task { [weak self, marketKit] in
            do {
                let message = try await marketKit.authKey(address: addressItem.address.hex)
                self?.state = .readyToActivate(message: message, account: addressItem.account, address: addressItem.address)
            } catch {
                self?.state = .failed(error: error)
            }
        }.store(in: &tasks)
    }

}

extension ActivateSubscriptionService {

    var activatedPublisher: AnyPublisher<Void, Never> {
        activatedSubject.eraseToAnyPublisher()
    }

    var activationErrorPublisher: AnyPublisher<Error, Never> {
        activationErrorSubject.eraseToAnyPublisher()
    }

    func retry() {
        fetchSubscriptions()
    }

    func sign() {
        guard case let .readyToActivate(message, account, address) = state else {
            return
        }

        guard let messageData = message.data(using: .utf8), let signedData = account.type.sign(message: messageData) else {
            return
        }

        activationState = .activating

        Task { [weak self, marketKit] in
            do {
                let token = try await marketKit.authenticate(signature: signedData.hs.hexString, address: address.hex)
                self?.subscriptionManager.set(authToken: token)
                self?.activatedSubject.send()
            } catch {
                self?.activationState = .ready
                self?.activationErrorSubject.send(error)
            }
        }.store(in: &tasks)
    }

}

extension ActivateSubscriptionService {

    private struct AddressItem {
        let account: Account
        let address: EvmKit.Address
    }

    enum State {
        case loading
        case noSubscriptions
        case readyToActivate(message: String, account: Account, address: EvmKit.Address)
        case failed(error: Error)
    }

    enum ActivationState {
        case ready
        case activating
    }

}
