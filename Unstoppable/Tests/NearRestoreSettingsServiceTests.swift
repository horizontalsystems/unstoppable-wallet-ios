import Combine
import Foundation
import GRDB
import MarketKit
import Testing
@testable import WalletCore

// When enabling NEAR asks which account a phrase opens (Android `RestoreSettingsServiceAccountPickerTest`).
// The restore flow and the "chain already enabled" rule live in view models built on Core.shared and are
// checked by hand (spec 2026-10-13 §11).
struct NearRestoreSettingsServiceTests {
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

    private func makeService() throws -> (RestoreSettingsService, RestoreSettingsManager, Recorder) {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("near-restore-settings-\(UUID().uuidString).sqlite").path
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

    @Test func restoredPhraseWithoutChoiceIsAsked() throws {
        let (service, _, recorder) = try makeService()

        service.approveSettings(token: Self.near, account: Self.account())

        #expect(recorder.approved.isEmpty)
        guard case .nearAccount? = recorder.requests.first?.type else {
            Issue.record("expected a NEAR account request")
            return
        }
    }

    @Test func restoredPhraseWithChoiceIsNotAsked() throws {
        let (service, manager, recorder) = try makeService()
        let account = Self.account()
        manager.save(settings: [.nearAccountId: "alice.near"], account: account, blockchainType: .near)

        service.approveSettings(token: Self.near, account: account)

        #expect(recorder.requests.isEmpty)
        #expect(recorder.approved == [[:]])
    }

    @Test func createdPhraseIsNotAsked() throws {
        let (service, _, recorder) = try makeService()

        service.approveSettings(token: Self.near, account: Self.account(origin: .created))

        #expect(recorder.requests.isEmpty)
        #expect(recorder.approved.count == 1)
        #expect(recorder.approved.first?.nearAccountId == nil)
    }

    @Test func watchAccountIsNotAsked() throws {
        let (service, _, recorder) = try makeService()

        service.approveSettings(token: Self.near, account: Self.account(type: .nearAddress(address: "alice.near")))

        #expect(recorder.requests.isEmpty)
        #expect(recorder.approved == [[:]])
    }

    @Test func enteredChoiceIsApproved() throws {
        let (service, _, recorder) = try makeService()

        service.enter(settings: [.nearAccountId: "alice.near"], token: Self.near)

        #expect(recorder.approved.first?.nearAccountId == "alice.near")
    }
}
