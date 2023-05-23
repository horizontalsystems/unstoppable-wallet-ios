import Foundation
import Combine
import EvmKit
import MarketKit
import HsToolKit
import HsExtensions

class ActivateSubscriptionService {
    let account: Account
    let evmAddress: EvmKit.Address
    private let marketKit: MarketKit.Kit
    private let subscriptionManager: SubscriptionManager
    private let accountManager: AccountManager
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var messageItem: MessageItem?
    @PostPublished private(set) var state: State = .fetchingMessage

    init?(address: String, marketKit: MarketKit.Kit, subscriptionManager: SubscriptionManager, accountManager: AccountManager) {
        var resolvedAccount: Account?
        var resolvedEvmAddress: EvmKit.Address?

        for account in accountManager.accounts {
            if let evmAddress = account.type.evmAddress(chain: App.shared.evmBlockchainManager.chain(blockchainType: .ethereum)),
               evmAddress.hex.caseInsensitiveCompare(address) == .orderedSame {
                resolvedAccount = account
                resolvedEvmAddress = evmAddress
                break
            }
        }

        guard let resolvedAccount, let resolvedEvmAddress else {
            return nil
        }

        account = resolvedAccount
        evmAddress = resolvedEvmAddress
        self.marketKit = marketKit
        self.subscriptionManager = subscriptionManager
        self.accountManager = accountManager

        fetchMessage()
    }

    private func fetchMessage() {
        state = .fetchingMessage

        Task { [weak self, marketKit, evmAddress] in
            do {
                let message = try await marketKit.authKey(address: evmAddress.hex)
                self?.handle(message: message)
            } catch {
                self?.state = .failedToFetchMessage(error: error)
            }
        }.store(in: &tasks)
    }

    private func handle(message: String) {
        messageItem = MessageItem(
                account: account,
                address: evmAddress,
                message: message
        )

        state = .readyToActivate
    }

    private func handle(token: String) {
        subscriptionManager.set(authToken: token)

        state = .activated
    }

}

extension ActivateSubscriptionService {

    func retry() {
        fetchMessage()
    }

    func sign() {
        guard let messageData = messageItem?.message.data(using: .utf8), let signedData = account.type.sign(message: messageData) else {
            return
        }

        state = .activating

        Task { [weak self, marketKit, evmAddress] in
            do {
                let token = try await marketKit.authenticate(signature: signedData.hs.hexString, address: evmAddress.hex)
                self?.handle(token: token)
            } catch {
                self?.state = .failedToActivate(error: error)
            }
        }.store(in: &tasks)
    }

}

extension ActivateSubscriptionService {

    struct MessageItem {
        let account: Account
        let address: EvmKit.Address
        let message: String
    }

    enum State {
        case fetchingMessage
        case readyToActivate
        case activating
        case activated
        case failedToFetchMessage(error: Error)
        case failedToActivate(error: Error)
    }

}
