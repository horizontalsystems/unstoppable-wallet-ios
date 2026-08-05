import BigInt
import Combine
import EvmKit
import Foundation
import GRDB
import HdWalletKit
import HsCryptoKit
import MarketKit
import Testing
import ThorChainKit
import TronKit
@testable import WalletCore

struct ThorChainKitManagerTests {
    @Test func unsupportedAccountFailsBeforeFactoryAccess() {
        let manager = ThorChainKitManager(endpointProvider: FailingThorChainEndpointProvider())
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
    }

    @Test func sameAccountUsesOneStartedWrapper() throws {
        let manager = ThorChainKitManager(endpointProvider: StaticThorChainEndpointProvider())
        let account = try Self.account(id: "same-account")

        let first = try manager.thorChainKitWrapper(account: account)
        let second = try manager.thorChainKitWrapper(account: account)

        #expect(first === second)
        #expecttry (first.thorChainKit.address.raw == AccountAddress.thorChainAddress(account: account).raw)
    }

    @Test func mnemonicDerivationMatchesFrozenVector() throws {
        let manager = ThorChainKitManager(endpointProvider: StaticThorChainEndpointProvider())
        let entropy = Crypto.sha256(Data("THR-104-S1-06-test-seed-v1".utf8))
        let account = try Self.account(id: "vector-account", entropy: entropy)

        let wrapper = try manager.thorChainKitWrapper(account: account)

        #expect(wrapper.thorChainKit.address.raw == "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008")
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

        #expecttry (AccountAddress.thorChainAddress(account: account) == expected)
    }

    @Test func changedAccountIdentityReplacesCachedWrapper() throws {
        let manager = ThorChainKitManager(endpointProvider: StaticThorChainEndpointProvider())
        let firstAccount = try Self.account(id: "first-account")
        let secondAccount = try Self.account(id: "second-account")
        let changedAccount = try Self.account(id: firstAccount.id)

        let first = try manager.thorChainKitWrapper(account: firstAccount)
        let second = try manager.thorChainKitWrapper(account: secondAccount)
        let changed = try manager.thorChainKitWrapper(account: changedAccount)

        #expect(first !== second)
        #expect(second !== changed)
    }

    @Test func concurrentSameAccountConstructionReturnsOneWrapper() throws {
        let manager = ThorChainKitManager(endpointProvider: StaticThorChainEndpointProvider())
        let account = try Self.account(id: "concurrent-account")
        let group = DispatchGroup()
        let lock = NSLock()
        var wrappers = [ThorChainKitWrapper]()

        for _ in 0 ..< 16 {
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
    }

    @Test func endpointAndMnemonicFailuresFailClosedBeforeFactory() throws {
        let endpointManager = ThorChainKitManager(endpointProvider: StaticThorChainEndpointProvider(host: "unapproved.example"))
        let account = try Self.account(id: "endpoint-account")

        do {
            _ = try endpointManager.thorChainKitWrapper(account: account)
            Issue.record("unapproved endpoint was accepted")
        } catch {
            #expect((error as? ThorChainKitManagerError) == .unapprovedEndpointHost("unapproved.example"))
        }

        let mnemonicManager = ThorChainKitManager(endpointProvider: FailingThorChainEndpointProvider())
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
    }

    @Test func selectedEndpointFamilyReplacesCachedWrapper() throws {
        let endpointManager = try Self.endpointManager(endpointProvider: TwoFamilyThorChainEndpointProvider())
        let manager = ThorChainKitManager(endpointManager: endpointManager)
        let account = try Self.account(id: "endpoint-selection")

        let first = try manager.thorChainKitWrapper(account: account)
        let endpointFamilies = try endpointManager.endpointFamilies()
        try endpointManager.setCurrent(endpointFamily: endpointFamilies[1])
        let second = try manager.thorChainKitWrapper(account: account)

        #expect(first !== second)
    }

    private static func account(id: String, entropy: Data? = nil) throws -> Account {
        let words = if let entropy {
            Mnemonic.generate(entropy: entropy, language: .english)
        } else {
            try Mnemonic.generate(wordCount: .twelve, language: .english)
        }

        return Account(
            id: id,
            level: 0,
            name: id,
            type: .mnemonic(words: words, salt: "", bip39Compliant: true),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )
    }

    private static func endpointManager(endpointProvider: IThorChainEndpointConfigurationProvider) throws -> ThorChainEndpointManager {
        let databaseURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("thorchain-kit-manager-tests-\(UUID().uuidString).sqlite")
        let dbPool = try DatabasePool(path: databaseURL.path)

        try dbPool.write { db in
            try db.create(table: BlockchainSettingRecord.databaseTableName) { table in
                table.column(BlockchainSettingRecord.Columns.blockchainUid.name, .text).notNull()
                table.column(BlockchainSettingRecord.Columns.key.name, .text).notNull()
                table.column(BlockchainSettingRecord.Columns.value.name, .text).notNull()
                table.primaryKey([BlockchainSettingRecord.Columns.blockchainUid.name, BlockchainSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        let recordStorage = try BlockchainSettingRecordStorage(dbPool: dbPool)
        let settingsStorage = BlockchainSettingsStorage(storage: recordStorage)
        return ThorChainEndpointManager(blockchainSettingsStorage: settingsStorage, endpointProvider: endpointProvider)
    }
}

private struct RegisteredThorAddressProvider: IAccountAddressProvider {
    let address: ThorChainKit.Address

    func evmAddress(account _: Account, blockchainType _: BlockchainType) throws -> EvmKit.Address? { nil }
    func tronAddress(account _: Account) throws -> TronKit.Address? { nil }
    func thorChainAddress(account: Account) throws -> ThorChainKit.Address? {
        account.id == "provider-boundary" ? address : nil
    }
}

private struct LegacyAddressProvider: IAccountAddressProvider {
    func evmAddress(account _: Account, blockchainType _: BlockchainType) throws -> EvmKit.Address? { nil }
    func tronAddress(account _: Account) throws -> TronKit.Address? { nil }
    func thorChainAddress(account _: Account) throws -> ThorChainKit.Address? { nil }
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
        return try ThorChainEndpointConfiguration(
            value: ThorChainKit.EndpointConfiguration(families: [family]),
            approvedMainnetHosts: ["thornode.ninerealms.com"]
        )
    }
}

private struct FailingThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        fatalError("provider must not be consulted")
    }
}

private struct TwoFamilyThorChainEndpointProvider: IThorChainEndpointConfigurationProvider {
    func configuration() throws -> ThorChainEndpointConfiguration {
        let first = try ThorChainKit.EndpointFamilyDescriptor(
            id: "first",
            cosmosRestURL: URL(string: "https://first-rest.example")!,
            cometBftURL: URL(string: "https://first-rpc.example")!
        )
        let second = try ThorChainKit.EndpointFamilyDescriptor(
            id: "second",
            cosmosRestURL: URL(string: "https://second-rest.example")!,
            cometBftURL: URL(string: "https://second-rpc.example")!
        )
        return try ThorChainEndpointConfiguration(
            value: ThorChainKit.EndpointConfiguration(families: [first, second]),
            approvedMainnetHosts: ["first-rest.example", "first-rpc.example", "second-rest.example", "second-rpc.example"]
        )
    }
}
