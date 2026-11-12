import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

/// The wallets a new account starts with (Android `CreateAccountModule.defaultTokenQueries`, #9896). Saving
/// them and their restore settings runs in a view model built on Core.shared and is checked by hand.
struct CreateAccountDefaultWalletsTests {
    @Test func defaultWalletsMatchAndroid() {
        #expect(CreateAccountViewModel.defaultTokenQueries == [
            TokenQuery(blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84)),
            TokenQuery(blockchainType: .ethereum, tokenType: .native),
            TokenQuery(blockchainType: .zcash, tokenType: .native),
            TokenQuery(blockchainType: .monero, tokenType: .native),
        ])
    }

    /// A default wallet that needs a birthday gets the current height, so a backup of a new account
    /// restores it from there and not from the first block
    @Test func birthdayChainsHaveCreatedAccountHeight() {
        for blockchainType in [BlockchainType.zcash, .monero] {
            let value = RestoreSettingType.birthdayHeight.createdAccountValue(blockchainType: blockchainType)
            #expect((value.flatMap { Int($0) } ?? 0) > 0, "\(blockchainType)")
        }
    }
}
