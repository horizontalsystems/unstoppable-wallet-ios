import Combine
import Foundation
import MarketKit

final class NearPlugin: BlockchainPlugin, AdapterCapability, LifecycleCapability, SendCapability, RestoreSettingsCapability, NetworkSettingsCapability, SwapCapability {
    private struct State {
        let nodeManager: NearNodeManager
        let kitManager: NearKitManager
        let coinManager: CoinManager
        let spamWrapper: SpamWrapper
    }

    let id = "near"
    let descriptors = [
        BlockchainDescriptor(
            type: .near,
            family: "near",
            order: 16,
            restoreSettingTypes: [.nearAccountId],
            // only a NEP-141 ft_transfer carries a memo; a NEAR transfer and a deposit have no field for it (Android memoDelivery = None)
            memo: MemoPolicy(type: .none, maxBytes: 256, ridesOpReturn: false),
            blockTime: 1,
            description: "NEAR, NEP-141 tokens",
            // Android NearAddressValidator refuses the account's own id as the receiver
            sendToSelfAllowed: false
        ),
    ]

    // Handler lists are constants: `HandlerRegistrations` reads them from an un-bootstrapped instance.
    let sendHandlers: [SendHandler.Type] = [NearSendHandler.self]
    let preSendHandlers: [PreSendHandler.Type] = [NearPreSendHandler.self]
    let restoreSettingsHandlers: [RestoreSettingsHandler.Type] = [NearAccountRestoreSettingsHandler.self]
    let nodeNetworkHandlers: [NodeNetworkHandlerProvider.Type] = [NearNodeNetworkHandler.self]
    let swapBroadcasters: [ISwapBroadcasterType.Type] = [NearSwapBroadcaster.self]

    private var state: State?

    private var bootstrapped: State {
        guard let state else {
            preconditionFailure("NearPlugin is not bootstrapped")
        }
        return state
    }

    var nodeManager: NearNodeManager {
        bootstrapped.nodeManager
    }

    var kitManager: NearKitManager {
        bootstrapped.kitManager
    }

    func bootstrap(context: PluginContext) throws {
        let nodeManager = NearNodeManager(blockchainSettingsStorage: context.blockchainSettingsStorage)
        let kitManager = NearKitManager(
            restoreStateManager: context.restoreStateManager, restoreSettingsManager: context.restoreSettingsManager, marketKit: context.marketKit, walletManager: context.walletManager,
            nodeManager: nodeManager, testNetManager: context.testNetManager
        )

        state = State(nodeManager: nodeManager, kitManager: kitManager, coinManager: context.coinManager, spamWrapper: context.spamWrapper)
    }
}

extension NearPlugin {
    /// For the static handler factories and screens of this folder, which run after launch. Not for generic code.
    static var shared: NearPlugin {
        guard let plugin = Core.shared.registry.plugin(NearPlugin.self) else {
            preconditionFailure("NearPlugin is not registered")
        }
        return plugin
    }
}

extension NearPlugin {
    func adapter(wallet: Wallet) -> IAdapter? {
        let kitManager = kitManager

        switch wallet.token.type {
        case .native:
            if let nearKit = try? kitManager.nearKit(account: wallet.account) {
                return NearAdapter(nearKit: nearKit)
            }

        case let .nep141(contractId):
            if let nearKit = try? kitManager.nearKit(account: wallet.account) {
                return NearTokenAdapter(nearKit: nearKit, nearKitManager: kitManager, token: wallet.token, contractId: contractId)
            }

        default: ()
        }

        return nil
    }

    func transactionsAdapter(source: TransactionSource, walletAdapter _: IAdapter) -> ITransactionsAdapter? {
        let state = bootstrapped
        let query = TokenQuery(blockchainType: .near, tokenType: .native)

        if let nearKit = state.kitManager.nearKit, let baseToken = try? state.coinManager.token(query: query) {
            return NearTransactionAdapter(nearKit: nearKit, source: source, baseToken: baseToken, coinManager: state.coinManager, spamWrapper: state.spamWrapper)
        }

        return nil
    }

    var adaptersInvalidated: AnyPublisher<BlockchainType, Never> {
        kitManager.kitStoppedPublisher
            .map { _ in BlockchainType.near }
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .eraseToAnyPublisher()
    }
}

extension NearPlugin {
    func didEnterBackground() {
        kitManager.nearKit?.pause()
    }

    func willEnterForeground() {
        kitManager.nearKit?.resume()
        kitManager.nearKit?.refresh()
    }

    func clear(exceptAccountIds: [String]) throws {
        try NearAdapter.clear(except: exceptAccountIds)
    }
}
