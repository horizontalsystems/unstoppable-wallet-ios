import BigInt
import Combine
import EvmKit
import Foundation
import HdWalletKit
import HsCryptoKit
import Testing
import ThorChainKit
import TronKit
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

    @Test func mnemonicDerivationMatchesFrozenVector() throws {
        let factory = RecordingThorChainKitFactory()
        let manager = ThorChainKitManager(
            endpointProvider: StaticThorChainEndpointProvider(),
            kitFactory: factory
        )
        let entropy = Crypto.sha256(Data("THR-104-S1-06-test-seed-v1".utf8))
        let account = try Self.account(id: "vector-account", entropy: entropy)

        let wrapper = try manager.thorChainKitWrapper(account: account)

        #expect(wrapper.thorChainKit.address.raw == "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008")
        #expect(factory.lastAddress == wrapper.thorChainKit.address.raw)
    }

    @Test func accountAddressUsesRegisteredThorProvider() throws {
        let expected = try ThorChainKit.Address("thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008", network: .mainnet)
        AccountAddress.register(RegisteredThorAddressProvider(address: expected))
        let account = Account(
            id: "provider-boundary",
            level: 0,
            name: "Provider boundary",
            type: .tonAddress(address: "unsupported"),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )

        #expect(try AccountAddress.thorChainAddress(account: account) == expected)
    }

    @Test func accountAddressProviderDefaultsThorToNil() throws {
        let account = try Self.account(id: "default-provider")

        #expect(try LegacyAddressProvider().thorChainAddress(account: account) == nil)
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

    private static func account(id: String, entropy: Data? = nil) throws -> Account {
        let words = if let entropy {
            Mnemonic.generate(entropy: entropy, language: .english)
        } else {
            try Mnemonic.generate(wordCount: .twelve, language: .english)
        }

        Account(
            id: id,
            level: 0,
            name: id,
            type: .mnemonic(words: words, salt: "", bip39Compliant: true),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )
    }
}

private struct RegisteredThorAddressProvider: IAccountAddressProvider {
    let address: ThorChainKit.Address

    func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address? { nil }
    func tronAddress(account: Account) throws -> TronKit.Address? { nil }
    func thorChainAddress(account: Account) throws -> ThorChainKit.Address? {
        account.id == "provider-boundary" ? address : nil
    }
}

private struct LegacyAddressProvider: IAccountAddressProvider {
    func evmAddress(account: Account, blockchainType: BlockchainType) throws -> EvmKit.Address? { nil }
    func tronAddress(account: Account) throws -> TronKit.Address? { nil }
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
    private(set) var kit: ManagerThorChainKitSpy!

    func kit(
        address: ThorChainKit.Address,
        walletId: String,
        endpoints: ThorChainKit.EndpointConfiguration
    ) throws -> any IThorChainKit {
        callCount += 1
        lastAddress = address.raw
        lastWalletId = walletId
        lastEndpointFamilyIds = endpoints.families.map(\.id)
        kit = ManagerThorChainKitSpy(address: address)
        return kit
    }
}

private final class ManagerThorChainKitSpy: IThorChainKit {
    let address: ThorChainKit.Address
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

    init(address: ThorChainKit.Address) {
        self.address = address
    }

    func start() { startCount += 1 }
    func stop() {}
    func refresh() {}
}
