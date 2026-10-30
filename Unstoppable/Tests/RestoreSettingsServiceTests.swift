import Combine
import Foundation
import GRDB
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

/// When enabling a chain asks its restore settings (Android `RestoreSettingsServiceAccountPickerTest`): the
/// service decides whether to ask, the registered handler decides what. The restore flow and the
/// "chain already enabled" rule live in view models built on Core.shared and are checked by hand.
@Suite(.serialized)
struct RestoreSettingsServiceTests {
    private static let mnemonic = AccountType.mnemonic(words: Array(repeating: "abandon", count: 11) + ["about"], salt: "", bip39Compliant: true)

    private static let near = Token(
        coin: Coin(uid: "near", name: "NEAR Protocol", code: "NEAR"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .native,
        decimals: 24
    )

    private final class Recorder {
        var requests = [RestoreSettingsService.Request]()
        var approved = [RestoreSettings]()
        var cancellables = Set<AnyCancellable>()
    }

    /// asks for a mnemonic only, as the NEAR handler does
    private final class StubHandler: RestoreSettingsHandler, IRestoreSettingsHandler {
        override class func instance(blockchainType: BlockchainType, accountType: AccountType?) -> IRestoreSettingsHandler? {
            guard blockchainType == .near, case .mnemonic = accountType else {
                return nil
            }
            return StubHandler()
        }

        func request(token _: Token, statPage _: StatPage?, onEnter _: @escaping (RestoreSettings) -> Void, onCancel _: @escaping () -> Void) {}
    }

    init() {
        RestoreSettingsHandlerFactory.reset()
        RestoreSettingsHandlerFactory.register(StubHandler.self)
    }

    private func makeService() throws -> (RestoreSettingsService, RestoreSettingsManager, Recorder) {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("restore-settings-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)
        try dbPool.write { db in
            try db.create(table: RestoreSettingRecord.databaseTableName) { t in
                t.column(RestoreSettingRecord.Columns.accountId.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.blockchainUid.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.key.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.value.name, .text)
                t.primaryKey([RestoreSettingRecord.Columns.accountId.name, RestoreSettingRecord.Columns.blockchainUid.name, RestoreSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        let manager = RestoreSettingsManager(storage: RestoreSettingsStorage(dbPool: dbPool))
        let service = RestoreSettingsService(manager: manager)
        let recorder = Recorder()
        service.requestPublisher.sink { recorder.requests.append($0) }.store(in: &recorder.cancellables)
        service.approveSettingsPublisher.sink { recorder.approved.append($0.settings) }.store(in: &recorder.cancellables)
        return (service, manager, recorder)
    }

    private static func account(type: AccountType = mnemonic, origin: AccountOrigin = .restored) -> Account {
        Account(id: UUID().uuidString, level: 0, name: "Account", type: type, origin: origin, backedUp: true, fileBackedUp: false)
    }

    @Test func missingSettingIsAskedByTheHandler() throws {
        let (service, _, recorder) = try makeService()

        service.approveSettings(token: Self.near, account: Self.account())

        #expect(recorder.approved.isEmpty)
        #expect(recorder.requests.first?.handler is StubHandler)
    }

    @Test func storedSettingIsNotAskedAgain() throws {
        let (service, manager, recorder) = try makeService()
        let account = Self.account()
        manager.save(settings: [.nearAccountId: "alice.near"], account: account, blockchainType: .near)

        service.approveSettings(token: Self.near, account: account)

        #expect(recorder.requests.isEmpty)
        #expect(recorder.approved == [[:]])
    }

    @Test func createdAccountIsNotAsked() throws {
        let (service, _, recorder) = try makeService()

        service.approveSettings(token: Self.near, account: Self.account(origin: .created))

        #expect(recorder.requests.isEmpty)
        #expect(recorder.approved.count == 1)
        #expect(recorder.approved.first?.nearAccountId == nil)
    }

    /// no handler for a watch account: nothing to ask
    @Test func accountWithoutHandlerIsNotAsked() throws {
        let (service, _, recorder) = try makeService()

        service.approveSettings(token: Self.near, account: Self.account(type: .nearAddress(address: "alice.near")))

        #expect(recorder.requests.isEmpty)
        #expect(recorder.approved == [[:]])
    }

    @Test func enteredSettingsAreApproved() throws {
        let (service, _, recorder) = try makeService()

        service.enter(settings: [.nearAccountId: "alice.near"], token: Self.near)

        #expect(recorder.approved.first?.nearAccountId == "alice.near")
    }

    @Test func factoryFindsTheFirstMatchingHandler() {
        #expect(RestoreSettingsHandlerFactory.handler(blockchainType: .near, accountType: Self.mnemonic) is StubHandler)
        #expect(RestoreSettingsHandlerFactory.handler(blockchainType: .near, accountType: .nearAddress(address: "alice.near")) == nil)
        #expect(RestoreSettingsHandlerFactory.handler(blockchainType: .bitcoin, accountType: Self.mnemonic) == nil)
    }
}
