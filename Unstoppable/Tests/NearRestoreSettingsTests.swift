import Foundation
import MarketKit
import Testing
@testable import WalletCore

// The NEAR account a restored phrase opens is kept as a restore setting, as Android does
// (`RestoreSettingType.NearAccountId`, "near_account_id"); its key is shared by the database and the backup.
struct NearRestoreSettingsTests {
    @Test func keyMatchesAndroid() {
        #expect(RestoreSettingType(rawValue: "near_account_id") == .nearAccountId)
        #expect(RestoreSettingType.nearAccountId.rawValue == "near_account_id")
    }

    @Test func chosenAccountIsRead() {
        let settings: RestoreSettings = [.nearAccountId: "alice.near"]

        #expect(settings.nearAccountId == "alice.near")
    }

    // a hand-edited backup must not leave the wallet without an account: the implicit one opens instead
    @Test func emptyOrInvalidAccountIsIgnored() {
        let empty: RestoreSettings = [.nearAccountId: ""]
        let invalid: RestoreSettings = [.nearAccountId: "Alice..near"]
        let none: RestoreSettings = [:]

        #expect(empty.nearAccountId == nil)
        #expect(invalid.nearAccountId == nil)
        #expect(none.nearAccountId == nil)
    }

    // a new phrase controls only its implicit account
    @Test func createdAccountHasNoChoice() {
        #expect(RestoreSettingType.nearAccountId.createdAccountValue(blockchainType: .near) == nil)
    }
}
