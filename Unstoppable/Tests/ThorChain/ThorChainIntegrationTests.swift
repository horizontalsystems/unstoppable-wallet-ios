import Foundation
import BigInt
import Combine
import HdWalletKit
import HsCryptoKit
import MarketKit
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainIntegrationTests {
    @Test func realCoreManagerUsesNativeRouteAndGenericLifecycle() throws {
        let core = try Self.core()
        let kitFactory = IntegrationThorChainKitFactory()
        let tronKitManager = TronKitManager(
            testNetManager: core.testNetManager,
            evmSyncSourceManager: core.evmSyncSourceManager
        )
        let thorChainKitManager = ThorChainKitManager(
            endpointProvider: IntegrationThorChainEndpointProvider(),
            kitFactory: kitFactory
        )
        let adapterFactory = AdapterFactory(
            evmBlockchainManager: core.evmBlockchainManager,
            evmSyncSourceManager: core.evmSyncSourceManager,
            moneroNodeManager: core.moneroNodeManager,
            zcashNodeManager: core.zcashNodeManager,
            btcBlockchainManager: core.btcBlockchainManager,
            tronKitManager: tronKitManager,
            thorChainKitManager: thorChainKitManager,
            diagnosticLogger: ThorChainDiagnosticLogger(logger: core.logger),
            tonKitManager: core.tonKitManager,
            stellarKitManager: core.stellarKitManager,
            zanoKitManager: core.zanoKitManager,
            solanaKitManager: core.solanaKitManager,
            restoreSettingsManager: core.restoreSettingsManager,
            coinManager: core.coinManager,
            spamWrapper: core.spamWrapper,
            evmLabelManager: core.evmLabelManager
        )
        let adapterManager = AdapterManager(
            adapterFactory: adapterFactory,
            walletManager: core.walletManager,
            evmBlockchainManager: core.evmBlockchainManager,
            tronKitManager: tronKitManager,
            tonKitManager: core.tonKitManager,
            stellarKitManager: core.stellarKitManager,
            zanoKitManager: core.zanoKitManager,
            solanaKitManager: core.solanaKitManager,
            btcBlockchainManager: core.btcBlockchainManager,
            moneroNodeManager: core.moneroNodeManager,
            zanoNodeManager: core.zanoNodeManager,
            zcashNodeManager: core.zcashNodeManager
        )
        let account = try Self.account()
        let wallet = Self.wallet(account: account)
        let unsupportedWallet = Wallet(
            token: Token(
                coin: Coin(uid: "thorchain-asset", name: "THORChain asset", code: "ASSET"),
                blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
                type: .eip20(address: "asset-reference"),
                decimals: 8
            ),
            account: account
        )
        #expect(adapterFactory.adapter(wallet: unsupportedWallet) == nil)
        let ready = DispatchSemaphore(value: 0)
        let subscription = adapterManager.adapterDataReadyObservable.subscribe(onNext: { data in
            if data.adapterMap.values.contains(where: { $0 is ThorChainAdapter }) {
                ready.signal()
            }
        })

        core.accountManager.save(account: account)
        core.walletManager.handle(newWallets: [wallet], deletedWallets: [])

        #expect(ready.wait(timeout: .now() + 5) == .success)
        let kit = try #require(kitFactory.kit)
        #expect(kitFactory.callCount == 1)
        #expect(kitFactory.startCountAtConstruction == [0])
        #expect(kit.startCount == 1)

        let managedWallet = try #require(adapterManager.adapterData.adapterMap.keys.first(where: {
            $0.token.blockchainType == .thorChain
        }))
        let globalRefresh = DispatchSemaphore(value: 0)
        kit.refreshHandler = { globalRefresh.signal() }
        adapterManager.refresh()
        #expect(globalRefresh.wait(timeout: .now() + 2) == .success)
        #expect(kit.refreshCount == 1)

        let walletRefresh = DispatchSemaphore(value: 0)
        kit.refreshHandler = { walletRefresh.signal() }
        adapterManager.refresh(wallet: managedWallet)
        #expect(walletRefresh.wait(timeout: .now() + 2) == .success)
        #expect(kit.refreshCount == 2)

        let stopped = DispatchSemaphore(value: 0)
        kit.stopHandler = { stopped.signal() }
        core.walletManager.delete(wallets: [managedWallet])
        #expect(stopped.wait(timeout: .now() + 5) == .success)
        #expect(kit.stopCount == 1)
        subscription.dispose()
        core.accountManager.delete(account: account)
    }

    @Test func genericAdapterManagerLifecycleForwardsExactlyOnce() {
        let adapter = AdapterManagerLifecycleSpy()

        AdapterManager.performLifecycle(.start, on: adapter)
        AdapterManager.performLifecycle(.refresh, on: adapter)
        AdapterManager.performLifecycle(.stop, on: adapter)

        #expect(adapter.startCount == 1)
        #expect(adapter.refreshCount == 1)
        #expect(adapter.stopCount == 1)
    }

    @Test func nativeRuneMetadataSelectsThorChainRouteIdentity() {
        let token = Token(
            coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .native,
            decimals: 8
        )

        #expect(token.blockchainType == .thorChain)
        #expect(token.type == .native)
        #expect(token.decimals == 8)
    }

    @Test func nonNativeThorTokenDoesNotMatchNativeRouteIdentity() {
        let token = Token(
            coin: Coin(uid: "thorchain-asset", name: "THORChain asset", code: "ASSET"),
            blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
            type: .eip20(address: "asset-reference"),
            decimals: 8
        )

        #expect(token.blockchainType == .thorChain)
        #expect(token.type != .native)
    }

    private static let coreLock = NSLock()

    private static func core() throws -> Core {
        coreLock.lock()
        defer { coreLock.unlock() }
        if let core = Core.instance {
            return core
        }
        try Core.initApp()
        return Core.shared
    }

    private static func account() throws -> Account {
        let entropy = Crypto.sha256(Data("THR-104-S1-06-test-seed-v1".utf8))
        let words = Mnemonic.generate(entropy: entropy, language: .english)
        return Account(
            id: "thorchain-integration-account",
            level: 0,
            name: "THORChain integration",
            type: .mnemonic(words: words, salt: "", bip39Compliant: true),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )
    }

    private static func wallet(account: Account) -> Wallet {
        Wallet(
            token: Token(
                coin: Coin(uid: "thorchain", name: "THORChain", code: "RUNE"),
                blockchain: Blockchain(type: .thorChain, name: "THORChain", explorerUrl: nil),
                type: .native,
                decimals: 8
            ),
            account: account
        )
    }
}

private struct IntegrationThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        let family = try ThorChainKit.EndpointFamilyDescriptor(
            id: "test-mainnet",
            cosmosRestURL: URL(string: "https://thornode.ninerealms.com")!,
            cometBftURL: URL(string: "https://thornode.ninerealms.com")!
        )
        return ThorChainEndpointConfiguration(
            value: try ThorChainKit.EndpointConfiguration(families: [family]),
            approvedMainnetHosts: ["thornode.ninerealms.com"]
        )
    }
}

private final class IntegrationThorChainKitFactory: IThorChainKitFactory {
    private(set) var kit: IntegrationThorChainKitSpy!
    private(set) var callCount = 0
    private(set) var startCountAtConstruction = [Int]()

    func kit(
        address: ThorChainKit.Address,
        walletId: String,
        endpoints: ThorChainKit.EndpointConfiguration
    ) throws -> any IThorChainKit {
        callCount += 1
        kit = IntegrationThorChainKitSpy(address: address)
        startCountAtConstruction.append(kit.startCount)
        return kit
    }
}

private final class IntegrationThorChainKitSpy: IThorChainKit {
    let address: ThorChainKit.Address
    let syncStateSubject = CurrentValueSubject<ThorChainKit.SyncState, Never>(.idle(cached: false))
    let accountStateSubject = CurrentValueSubject<ThorChainKit.AccountState?, Never>(nil)
    var startCount = 0
    var stopCount = 0
    var refreshCount = 0
    var refreshHandler: (() -> Void)?
    var stopHandler: (() -> Void)?

    init(address: ThorChainKit.Address) {
        self.address = address
    }

    var network: ThorChainKit.Network { address.network }
    var lastBlockHeight: Int64? { nil }
    var syncState: ThorChainKit.SyncState { syncStateSubject.value }
    var accountState: ThorChainKit.AccountState? { nil }
    var runeBalance: BigUInt { 0 }
    var accountExists: Bool { false }
    var lastBlockHeightPublisher: AnyPublisher<Int64?, Never> { Just(nil).eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<ThorChainKit.SyncState, Never> { syncStateSubject.eraseToAnyPublisher() }
    var accountStatePublisher: AnyPublisher<ThorChainKit.AccountState?, Never> { accountStateSubject.eraseToAnyPublisher() }

    func start() { startCount += 1 }
    func stop() {
        stopCount += 1
        stopHandler?()
    }
    func refresh() {
        refreshCount += 1
        refreshHandler?()
    }
}

private final class AdapterManagerLifecycleSpy: IAdapter {
    var startCount = 0
    var stopCount = 0
    var refreshCount = 0

    func start() { startCount += 1 }
    func stop() { stopCount += 1 }
    func refresh() { refreshCount += 1 }

    var statusInfo: [(String, Any)] { [] }
    var debugInfo: String { "" }
}
