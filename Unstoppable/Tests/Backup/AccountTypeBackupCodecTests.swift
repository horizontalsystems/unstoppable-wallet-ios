import Foundation
import HsExtensions
import MarketKit
import TronKit
import Testing
@testable import WalletCore

// Golden vectors shared with Android: the bytes on the left are what BackupLocalModule writes and reads.
// A new account type must appear here, or the name table test below fails.
struct AccountTypeBackupCodecTests {
    // MARK: names

    @Test func writesAndroidNames() {
        #expect(AccountType.Abstract.stellarSecretKey.rawValue == "secret_key")
        #expect(AccountType.Abstract.stellarAccount.rawValue == "stellar_address")
        #expect(AccountType.Abstract.btcAddress.rawValue == "bitcoin_address")
    }

    @Test func everyNameIsPinned() {
        let expected: [AccountType.Abstract: String] = [
            .mnemonic: "mnemonic",
            .evmPrivateKey: "private_key",
            .trcPrivateKey: "tron_private_key",
            .stellarSecretKey: "secret_key",
            .passkeyOwned: "passkey_owned",
            .evmAddress: "evm_address",
            .tronAddress: "tron_address",
            .tonAddress: "ton_address",
            .solanaAddress: "solana_address",
            .stellarAccount: "stellar_address",
            .xrpAddress: "xrp_address",
            .thorChainAddress: "thorchain_address",
            .mayaChainAddress: "mayachain_address",
            .hdExtendedKey: "hd_extended_key",
            .btcAddress: "bitcoin_address",
            .moneroWatchAccount: "monero_watch_account",
            .moneroMnemonic: "monero_mnemonic",
        ]

        for type in AccountType.Abstract.allCases {
            #expect(expected[type] == type.rawValue, "account type \(type) is missing from the pinned name table")
        }
    }

    @Test func readsLegacyIosNames() throws {
        #expect(try decodeAbstract("secret_key") == .stellarSecretKey)
        #expect(try decodeAbstract("stellar_secret_key") == .stellarSecretKey)
        #expect(try decodeAbstract("stellar_address") == .stellarAccount)
        #expect(try decodeAbstract("stellar_account") == .stellarAccount)
        #expect(try decodeAbstract("bitcoin_address") == .btcAddress)
        #expect(try decodeAbstract("btc_address_key") == .btcAddress)
        #expect(try decodeAbstract("thorchain_address") == .thorChainAddress)
        #expect(try decodeAbstract("mayachain_address") == .mayaChainAddress)
        #expect(throws: (any Error).self) { try decodeAbstract("unknown_address") }
    }

    // MARK: private keys

    @Test func normalizesAndroidPrivateKeys() throws {
        let key = Data(repeating: 0x8F, count: 32) // high bit set: Android writes 33 bytes

        #expect(AccountTypeBackupCodec.normalizedPrivateKey(key) == key)
        #expect(AccountTypeBackupCodec.normalizedPrivateKey(Data([0]) + key) == key)

        let short = Data(repeating: 0x11, count: 31) // Android drops a leading zero byte
        #expect(AccountTypeBackupCodec.normalizedPrivateKey(short) == Data([0]) + short)
    }

    @Test func rejectsKeysOutsideTheCurve() {
        #expect(AccountTypeBackupCodec.normalizedPrivateKey(Data()) == nil)
        #expect(AccountTypeBackupCodec.normalizedPrivateKey(Data(repeating: 0, count: 32)) == nil)
        #expect(AccountTypeBackupCodec.normalizedPrivateKey(Data(repeating: 0xFF, count: 32)) == nil) // ≥ order
        #expect(AccountTypeBackupCodec.normalizedPrivateKey(Data(repeating: 0x8F, count: 33)) == nil) // no leading zero
    }

    @Test func decodesPrivateKeyOfEitherLength() throws {
        let key = Data(repeating: 0x8F, count: 32)

        guard case let .evmPrivateKey(data) = try decoded(Data([0]) + key, .evmPrivateKey).accountType else {
            Issue.record("not an evm private key")
            return
        }

        #expect(data == key)
        #expect(AccountTypeBackupCodec.decode(data: Data(repeating: 0, count: 32), type: .trcPrivateKey) == nil)
    }

    // MARK: BTC

    @Test func decodesBothBtcFormats() throws {
        let android = "bc1qtest|bitcoin|derived:bip84"
        let legacy = "bc1qtest&bitcoin|derived:bip84"

        for string in [android, legacy] {
            guard case let .btcAddress(address, blockchainType, tokenType) = try decoded(string.hs.data, .btcAddress).accountType else {
                Issue.record("not a btc address for \(string)")
                return
            }

            #expect(address == "bc1qtest")
            #expect(blockchainType == .bitcoin)
            #expect(tokenType == .derived(derivation: .bip84))
        }
    }

    @Test func writesBtcInAndroidFormat() {
        let accountType = AccountType.btcAddress(address: "bc1qtest", blockchainType: .bitcoin, tokenType: .derived(derivation: .bip84))
        let data = AccountTypeBackupCodec.data(accountType: accountType, moneroHeight: 0)

        #expect(String(decoding: data, as: UTF8.self) == "bc1qtest|bitcoin|derived:bip84")
    }

    @Test func rejectsBtcOnAnotherChain() {
        #expect(AccountTypeBackupCodec.decode(data: "0xtest|ethereum|native".hs.data, type: .btcAddress) == nil)
        #expect(AccountTypeBackupCodec.decode(data: "bc1qtest|bitcoin".hs.data, type: .btcAddress) == nil)
    }

    // MARK: Monero

    @Test func takesMoneroHeightFromAccountData() throws {
        let result = try decoded("4addr|viewkey|3200000".hs.data, .moneroWatchAccount)

        guard case let .moneroWatchAccount(address, viewKey) = result.accountType else {
            Issue.record("not a monero watch account")
            return
        }

        #expect(address == "4addr")
        #expect(viewKey == "viewkey")
        #expect(result.restoreSettings[.monero]?.birthdayHeight == 3_200_000)
    }

    @Test func leavesHeightToWalletSettingsWhenDataHasTwoParts() throws {
        let result = try decoded("4addr|viewkey".hs.data, .moneroWatchAccount)
        #expect(result.restoreSettings.isEmpty)
    }

    @Test func threePartDataAlwaysWinsOverWalletSettings() throws {
        // the account data is authenticated, the plain-text wallet settings are not
        for string in ["4addr|viewkey|-1", "4addr|viewkey|abc", "4addr|viewkey|0", "4addr|viewkey|999999999999"] {
            let result = try decoded(string.hs.data, .moneroWatchAccount)
            #expect(result.restoreSettings[.monero]?.birthdayHeight == 0, "unusable height in \(string) must land as 0")
        }

        #expect(AccountTypeBackupCodec.decode(data: "4addr|viewkey|1|2".hs.data, type: .moneroWatchAccount) == nil)
    }

    @Test func writesMoneroHeightForAndroid() {
        let accountType = AccountType.moneroWatchAccount(address: "4addr", viewKey: "viewkey")
        let data = AccountTypeBackupCodec.data(accountType: accountType, moneroHeight: 3_200_000)

        #expect(String(decoding: data, as: UTF8.self) == "4addr|viewkey|3200000")
    }

    // MARK: XRP, Tron, mnemonic

    @Test func normalizesXrpXAddress() throws {
        let classic = "rG1QQv2nh2gr7RCZ1P8YYcBUKCCN633jCn"
        let xAddress = "XVMEz67QftZamMQtmWCaW2urrZFhrT5UUETXFsPhSPzWPRY" // same account, no tag

        guard case let .xrpAddress(address) = try decoded(xAddress.hs.data, .xrpAddress).accountType else {
            Issue.record("not an xrp address")
            return
        }

        #expect(address == classic)

        guard case let .xrpAddress(plain) = try decoded(classic.hs.data, .xrpAddress).accountType else {
            Issue.record("not an xrp address")
            return
        }

        #expect(plain == classic)
    }

    @Test func writesTronInBase58AndReadsBothForms() throws {
        let base58 = "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE"
        let accountType = try #require(AccountTypeBackupCodec.decode(data: base58.hs.data, type: .tronAddress)?.accountType)

        guard case let .tronAddress(address) = accountType else {
            Issue.record("not a tron address")
            return
        }

        #expect(String(decoding: AccountTypeBackupCodec.data(accountType: accountType, moneroHeight: 0), as: UTF8.self) == base58)

        // the hex form iOS wrote until this change
        guard case let .tronAddress(fromHex) = try decoded(address.hex.hs.data, .tronAddress).accountType else {
            Issue.record("not a tron address")
            return
        }

        #expect(fromHex.base58 == base58)
    }

    // Android stores the address as typed; it comes back in the kit's lowercase form, and anything
    // that is not an address of that chain skips the account
    @Test func readsThorAndMayaAddressesInCanonicalForm() throws {
        let thor = "thor1le9eykyndunax8k24w8fykd8ndx35w2h27c008"
        let maya = "maya1le9eykyndunax8k24w8fykd8ndx35w2h2fxreh"

        #expect(try decoded(thor.uppercased().hs.data, .thorChainAddress).accountType == .thorChainAddress(address: thor))
        #expect(try decoded(maya.hs.data, .mayaChainAddress).accountType == .mayaChainAddress(address: maya))
        #expect(String(decoding: AccountTypeBackupCodec.data(accountType: .thorChainAddress(address: thor), moneroHeight: 0), as: UTF8.self) == thor)

        #expect(AccountTypeBackupCodec.decode(data: maya.hs.data, type: .thorChainAddress) == nil)
        #expect(AccountTypeBackupCodec.decode(data: thor.hs.data, type: .mayaChainAddress) == nil)
        #expect(AccountTypeBackupCodec.decode(data: "garbage".hs.data, type: .thorChainAddress) == nil)
    }

    // MARK: other types

    @Test func writesPlainStringTypesAsIs() {
        let ton = AccountType.tonAddress(address: "UQtest")
        #expect(String(decoding: AccountTypeBackupCodec.data(accountType: ton, moneroHeight: 0), as: UTF8.self) == "UQtest")

        let stellar = AccountType.stellarAccount(accountId: "GTEST")
        #expect(String(decoding: AccountTypeBackupCodec.data(accountType: stellar, moneroHeight: 0), as: UTF8.self) == "GTEST")
    }

    @Test func skipsPasskey() {
        #expect(AccountTypeBackupCodec.decode(data: Data(repeating: 1, count: 16), type: .passkeyOwned) == nil)
    }

    // MARK: helpers

    private func decoded(_ data: Data, _ type: AccountType.Abstract) throws -> AccountTypeBackupCodec.Decoded {
        try #require(AccountTypeBackupCodec.decode(data: data, type: type))
    }

    private func decodeAbstract(_ name: String) throws -> AccountType.Abstract {
        try JSONDecoder().decode(AccountType.Abstract.self, from: Data("\"\(name)\"".utf8))
    }
}
