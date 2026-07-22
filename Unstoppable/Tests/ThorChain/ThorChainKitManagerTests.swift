import BigInt
import Combine
import Foundation
import HdWalletKit
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainKitManagerTests {
    @Test func unsupportedAccountFailsBeforeFactoryAccess() {
        let factory = RecordingThorChainKitFactory()
        let manager = ThorChainKitManager(
            endpointProvider: FailingThorChainEndpointProvider(),
            kitFactory: factory
        )
        let account = Account(
            id: "unsupported",
            level: 0,
            name: "Unsupported",
            type: .tonAddress(address: "unsupported"),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )

        do {
            _ = try manager.thorChainKitWrapper(account: account)
            Issue.record("unsupported account was accepted")
        } catch {
            #expect((error as? ThorChainKitManagerError) == .unsupportedAccount)
        }
        #expect(factory.callCount == 0)
    }

    @Test func sameAccountUsesOneUnstartedWrapperAndExactFactoryArguments() throws {
        let factory = RecordingThorChainKitFactory()
        let manager = ThorChainKitManager(
            endpointProvider: StaticThorChainEndpointProvider(),
            kitFactory: factory
        )
        let account = try Self.account(id: "same-account")

        let first = try manager.thorChainKitWrapper(account: account)
        let second = try manager.thorChainKitWrapper(account: account)

        #expect(first === second)
        #expect(factory.callCount == 1)
        #expect(factory.lastWalletId == account.id)
        #expect(factory.lastAddress == first.thorChainKit.address.raw)
        #expect(factory.lastEndpointFamilyIds == ["test-mainnet"])
        #expect(factory.kit.startCount == 0)
    }

    @Test func changedAccountIdentityReplacesCachedWrapper() throws {
        let factory = RecordingThorChainKitFactory()
        let manager = ThorChainKitManager(
            endpointProvider: StaticThorChainEndpointProvider(),
            kitFactory: factory
        )
        let firstAccount = try Self.account(id: "first-account")
        let secondAccount = try Self.account(id: "second-account")
        let changedAccount = try Self.account(id: firstAccount.id)

        let first = try manager.thorChainKitWrapper(account: firstAccount)
        let second = try manager.thorChainKitWrapper(account: secondAccount)
        let changed = try manager.thorChainKitWrapper(account: changedAccount)

        #expect(first !== second)
        #expect(second !== changed)
        #expect(factory.callCount == 3)
    }

    @Test func concurrentSameAccountConstructionReturnsOneWrapper() throws {
        let factory = RecordingThorChainKitFactory()
        let manager = ThorChainKitManager(
            endpointProvider: StaticThorChainEndpointProvider(),
            kitFactory: factory
        )
        let account = try Self.account(id: "concurrent-account")
        let group = DispatchGroup()
        let lock = NSLock()
        var wrappers = [ThorChainKitWrapper]()

        for _ in 0..<16 {
            group.enter()
            DispatchQueue.global().async {
                if let wrapper = try? manager.thorChainKitWrapper(account: account) {
                    lock.lock()
                    wrappers.append(wrapper)
                    lock.unlock()
                }
                group.leave()
            }
        }
        #expect(group.wait(timeout: .now() + 2) == .success)

        let identities = Set(wrappers.map(ObjectIdentifier.init))
        #expect(identities.count == 1)
        #expect(factory.callCount == 1)
    }

    @Test func endpointAndMnemonicFailuresFailClosedBeforeFactory() throws {
        let endpointFactory = RecordingThorChainKitFactory()
        let endpointManager = ThorChainKitManager(
            endpointProvider: StaticThorChainEndpointProvider(host: "unapproved.example"),
            kitFactory: endpointFactory
        )
        let account = try Self.account(id: "endpoint-account")

        do {
            _ = try endpointManager.thorChainKitWrapper(account: account)
            Issue.record("unapproved endpoint was accepted")
        } catch {
            #expect((error as? ThorChainKitManagerError) == .unapprovedEndpointHost("unapproved.example"))
        }
        #expect(endpointFactory.callCount == 0)

        let mnemonicFactory = RecordingThorChainKitFactory()
        let mnemonicManager = ThorChainKitManager(
            endpointProvider: FailingThorChainEndpointProvider(),
            kitFactory: mnemonicFactory
        )
        let noSeed = Account(
            id: "no-seed",
            level: 0,
            name: "No seed",
            type: .mnemonic(words: [], salt: "", bip39Compliant: true),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )

        do {
            _ = try mnemonicManager.thorChainKitWrapper(account: noSeed)
            Issue.record("missing mnemonic seed was accepted")
        } catch {
            #expect((error as? ThorChainKitManagerError) == .mnemonicNoSeed)
        }
        #expect(mnemonicFactory.callCount == 0)
    }

    private static func account(id: String) throws -> Account {
        Account(
            id: id,
            level: 0,
            name: id,
            type: .mnemonic(words: try Mnemonic.generate(wordCount: .twelve, language: .english), salt: "", bip39Compliant: true),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )
    }
}

private struct StaticThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    let host: String

    init(host: String = "thornode.ninerealms.com") {
        self.host = host
    }

    func configuration() throws -> ThorChainEndpointConfiguration {
        let family = try ThorChainKit.EndpointFamilyDescriptor(
            id: "test-mainnet",
            cosmosRestURL: URL(string: "https://\(host)")!,
            cometBftURL: URL(string: "https://\(host)")!
        )
        return ThorChainEndpointConfiguration(
            value: try ThorChainKit.EndpointConfiguration(families: [family]),
            approvedMainnetHosts: ["thornode.ninerealms.com"]
        )
    }
}

private struct FailingThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        fatalError("provider must not be consulted")
    }
}

private final class RecordingThorChainKitFactory: IThorChainKitFactory {
    var callCount = 0
    var lastAddress = ""
    var lastWalletId = ""
    var lastEndpointFamilyIds = [String]()
    let kit = ManagerThorChainKitSpy()

    func kit(
        address: ThorChainKit.Address,
        walletId: String,
        endpoints: ThorChainKit.EndpointConfiguration
    ) throws -> any IThorChainKit {
        callCount += 1
        lastAddress = address.raw
        lastWalletId = walletId
        lastEndpointFamilyIds = endpoints.families.map(\.id)
        return kit
    }
}

private final class ManagerThorChainKitSpy: IThorChainKit {
    let address = try! ThorChainKit.Address("thor1x0jkvqdh2hlpeztd5zyyk70n3efx6mhudkmnn2", network: .mainnet)
    let syncStateSubject = CurrentValueSubject<ThorChainKit.SyncState, Never>(.idle(cached: false))
    let accountStateSubject = CurrentValueSubject<ThorChainKit.AccountState?, Never>(nil)
    var network: ThorChainKit.Network { address.network }
    var lastBlockHeight: Int64? { nil }
    var syncState: ThorChainKit.SyncState { syncStateSubject.value }
    var accountState: ThorChainKit.AccountState? { nil }
    var runeBalance: BigUInt = 0
    var accountExists: Bool { false }
    var lastBlockHeightPublisher: AnyPublisher<Int64?, Never> { Just(nil).eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<ThorChainKit.SyncState, Never> { syncStateSubject.eraseToAnyPublisher() }
    var accountStatePublisher: AnyPublisher<ThorChainKit.AccountState?, Never> { accountStateSubject.eraseToAnyPublisher() }
    var startCount = 0

    func start() { startCount += 1 }
    func stop() {}
    func refresh() {}
}
