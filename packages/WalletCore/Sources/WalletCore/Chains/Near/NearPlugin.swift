import Combine
import MarketKit

final class NearPlugin: BlockchainPlugin, AdapterCapability, LifecycleCapability {
    private struct State {
        let nodeManager: NearNodeManager
        let kitManager: NearKitManager
        let coinManager: CoinManager
        let spamWrapper: SpamWrapper
    }

    let id = "near"
    let descriptors = [BlockchainDescriptor(type: .near, family: "near")]

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
        kitManager.kitStoppedPublisher.map { _ in BlockchainType.near }.eraseToAnyPublisher()
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
