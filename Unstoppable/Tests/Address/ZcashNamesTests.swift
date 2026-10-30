import Foundation
import HsToolKit
import MarketKit
import RxSwift
import Testing
@testable import WalletCore
import ZODLSwiftWalletSDK

/// Zcash Names on the Name Notes protocol, with live mainnet Resolver responses as vectors.
struct ZcashNamesTests {
    // MARK: - Name normalization

    @Test func normalizeAcceptsBothSuffixesInAnyCase() {
        #expect(name("alice.zcash") == "alice")
        #expect(name("alice.zec") == "alice")
        #expect(name("Alice.ZCASH") == "alice")
        #expect(name("aLice.Zec") == "alice")
        #expect(name("  alice.zcash \n") == "alice")
        #expect(name("bob42.zec") == "bob42")
        #expect(name("123.zec") == "123")
        #expect(name("a.zcash") == "a")
        #expect(name(String(repeating: "a", count: 63) + ".zcash") == String(repeating: "a", count: 63))
    }

    @Test func normalizeKeepsTheTypedSuffix() {
        #expect(ZnsAddressParserItem.normalize("Alice.ZEC")?.suffix == ".zec")
        #expect(ZnsAddressParserItem.normalize("alice.zcash")?.suffix == ".zcash")
    }

    /// the suffix is required: a bare word is indistinguishable from a partly typed address
    @Test func normalizeRejectsBareNamesAndAddresses() {
        #expect(name("alice") == nil)
        #expect(name("thebackupkid") == nil)
        #expect(name(Self.thebackupkidAddress) == nil)
        #expect(name("t1RBzFrCTWSZe3FJbDewtveUMRX2og4kKph") == nil)
        #expect(name("zs1abc") == nil)
    }

    @Test func normalizeRejectsInvalidNames() {
        #expect(name("") == nil)
        #expect(name(".zcash") == nil)
        #expect(name(".zec") == nil)
        #expect(name("my-name.zcash") == nil)
        #expect(name("my_name.zec") == nil)
        #expect(name("has space.zcash") == nil)
        #expect(name("café.zcash") == nil)
        #expect(name("\u{130}lice.zec") == nil)
        #expect(name("alice.zcash.zcash") == nil)
        #expect(name("alice.eth") == nil)
        #expect(name(String(repeating: "a", count: 64) + ".zcash") == nil)
        // `$` in a regex also matches before a final line break; the name must end at the suffix
        #expect(name("alice\n.zcash") == nil)
    }

    /// as on Android: Unicode lowercasing folds the Kelvin sign into an ASCII "k"
    @Test func normalizeFoldsKelvinSignLikeAndroid() {
        #expect(name("\u{212A}im.zcash") == "kim")
    }

    // MARK: - Registry check

    @Test func pinnedViewingKeyIsThePublishedMainnetKey() {
        #expect(ZnsResolver.mainnetViewingKey == Self.publishedMainnetViewingKey)
    }

    @Test func liveMainnetStatusIsAccepted() throws {
        try ZnsResolver.verifyRegistry(json: json(Self.statusBody))
    }

    @Test(arguments: [
        Self.testnetViewingKey,
        String(Self.publishedMainnetViewingKey.dropLast()),
        Self.publishedMainnetViewingKey + "q",
        Self.publishedMainnetViewingKey.uppercased(),
    ])
    func anotherRegistryIsUnknown(viewingKey: String) throws {
        let body = #"{"jsonrpc":"2.0","id":1,"result":{"synced_height":1,"synced":true,"viewing_key":"\#(viewingKey)"}}"#

        let error = #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.verifyRegistry(json: json(body)) }

        #expect(error.map(kind) == "unknownRegistry")
    }

    @Test(arguments: [
        #"{"jsonrpc":"2.0","id":1,"result":{"synced":true}}"#,
        #"{"jsonrpc":"2.0","id":1,"result":{"viewing_key":5}}"#,
        #"{"jsonrpc":"2.0","id":1,"result":null}"#,
        #"{"jsonrpc":"2.0","id":1,"result":[]}"#,
        #"{"jsonrpc":"2.0","id":1}"#,
    ])
    func malformedStatusIsRejected(body: String) throws {
        let error = #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.verifyRegistry(json: json(body)) }

        #expect(error.map(kind) == "malformedResponse")
    }

    @Test func statusRpcErrorIsSurfaced() throws {
        let body = #"{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"Internal error"}}"#

        let error = #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.verifyRegistry(json: json(body)) }

        expectRpcError(error, code: -32603, message: "Internal error")
    }

    // MARK: - Response parsing

    @Test func parsePermanentRegistration() throws {
        let registration = try #require(try registration(Self.thebackupkidBody))

        #expect(registration.name == "thebackupkid")
        #expect(registration.address == Self.thebackupkidAddress)
    }

    @Test func parseFixedTermRegistration() throws {
        let registration = try #require(try registration(Self.zechariahBody))

        #expect(registration.name == "zechariah")
        #expect(registration.address == Self.zechariahAddress)
    }

    @Test func parseNotRegistered() throws {
        let registration = try registration(#"{"jsonrpc":"2.0","id":1,"result":null}"#)

        #expect(registration == nil)
    }

    @Test func parseRpcErrorIsSurfaced() throws {
        let body = #"{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid params"}}"#

        let error = #expect(throws: ZnsResolver.ResolveError.self) { try registration(body) }

        expectRpcError(error, code: -32602, message: "Invalid params")
    }

    @Test(arguments: [
        // the Resolver answers an address query with an array; a name query never should
        #"{"jsonrpc":"2.0","id":1,"result":[]}"#,
        #"{"jsonrpc":"2.0","id":1,"result":{"address":"u1example"}}"#,
        #"{"jsonrpc":"2.0","id":1,"result":{"name":"alice"}}"#,
        #"{"jsonrpc":"2.0","id":1,"result":{"name":"alice","address":5}}"#,
        #"{"jsonrpc":"2.0","id":1}"#,
        #""not an object""#,
    ])
    func parseRejectsMalformedBodies(body: String) throws {
        let error = #expect(throws: ZnsResolver.ResolveError.self) { try registration(body) }

        #expect(error.map(kind) == "malformedResponse")
    }

    /// the expiry is the Resolver's business: a lapsed name resolves until its release lands on chain
    @Test(arguments: [#""none""#, #""1""#, #""1824002006""#, #""garbage""#, "null"])
    func parseIgnoresExpiry(expiresAt: String) throws {
        let body = #"{"jsonrpc":"2.0","id":1,"result":{"name":"alice","address":"u1example","last_action":"claim","expires_at":\#(expiresAt)}}"#

        let registration = try #require(try registration(body))

        #expect(registration.address == "u1example")
    }

    // MARK: - Validation

    @Test func validateReturnsAddressOfMatchingRegistration() throws {
        let registration = try #require(try registration(Self.thebackupkidBody))

        let address = try ZnsResolver.validate(name: "thebackupkid", registration: registration)

        #expect(address == Self.thebackupkidAddress)
    }

    /// a record of another name must not answer this query, and names match bytes, not canonical equivalence
    @Test(arguments: [
        ("alice", "thebackupkid"),
        ("thebackupkid.zec", "thebackupkid"),
        ("TheBackupKid", "thebackupkid"),
        ("cafe\u{301}", "caf\u{e9}"),
    ])
    func validateRejectsRegistrationOfAnotherName(recordName: String, query: String) throws {
        let registration = ZnsResolver.Registration(name: recordName, address: Self.thebackupkidAddress)

        let error = #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.validate(name: query, registration: registration) }

        #expect(error.map(kind) == "nameMismatch")
    }

    // MARK: - Parser item

    @Test func liveAddressesPassTheZcashValidator() async throws {
        for address in [Self.thebackupkidAddress, Self.zechariahAddress] {
            let parsed = try await handle(zcashParserItem(), address)

            #expect(parsed.raw == address)
        }
    }

    @Test func parserItemTakesOnlyNames() async throws {
        let item = ZnsAddressParserItem(resolver: StubZnsResolver(address: nil), rawAddressParserItem: zcashParserItem())

        let name = try await isValid(item, "thebackupkid.zec")
        let bareWord = try await isValid(item, "thebackupkid")
        let address = try await isValid(item, Self.thebackupkidAddress)

        #expect(name)
        #expect(!bareWord)
        #expect(!address)
    }

    @Test func handleQueriesTheNormalizedNameAndKeepsTheTypedSuffix() async throws {
        let resolver = StubZnsResolver(address: Self.thebackupkidAddress)
        let item = ZnsAddressParserItem(resolver: resolver, rawAddressParserItem: zcashParserItem())

        let address = try await handle(item, " TheBackupKid.ZEC ")

        #expect(resolver.queries == ["thebackupkid"])
        #expect(address.raw == Self.thebackupkidAddress)
        #expect(address.domain == "thebackupkid.zec")
        #expect(address.blockchainType == .zcash)
    }

    @Test(arguments: ["thebackupkid", Self.thebackupkidAddress, "my-name.zec"])
    func handleNeverQueriesForNonNames(input: String) async {
        let resolver = StubZnsResolver(address: Self.thebackupkidAddress)
        let item = ZnsAddressParserItem(resolver: resolver, rawAddressParserItem: zcashParserItem())

        await #expect(throws: AddressService.AddressError.self) { try await handle(item, input) }
        #expect(resolver.queries.isEmpty)
    }

    @Test func unregisteredNameIsAnInvalidAddress() async {
        let item = ZnsAddressParserItem(resolver: StubZnsResolver(address: nil), rawAddressParserItem: zcashParserItem())

        await #expect(throws: AddressService.AddressError.self) { try await handle(item, "definitelynotregistered.zcash") }
    }

    @Test func failedLookupIsAnInvalidAddress() async {
        let item = ZnsAddressParserItem(resolver: StubZnsResolver(error: ZnsResolver.ResolveError.unknownRegistry), rawAddressParserItem: zcashParserItem())

        await #expect(throws: AddressService.AddressError.self) { try await handle(item, "thebackupkid.zec") }
    }

    @Test func unreachableResolverIsAnInvalidAddress() async {
        let item = ZnsAddressParserItem(resolver: ZnsResolver(networkManager: NetworkManager(), url: "http://127.0.0.1:1"), rawAddressParserItem: zcashParserItem())

        await #expect(throws: AddressService.AddressError.self) { try await handle(item, "thebackupkid.zec") }
    }

    /// a resolved address still has to be a Zcash address; the regular parser refuses it
    @Test func garbageResolvedAddressIsRefused() async {
        let item = ZnsAddressParserItem(resolver: StubZnsResolver(address: "u1garbage"), rawAddressParserItem: zcashParserItem())

        await #expect(throws: (any Error).self) { try await handle(item, "thebackupkid.zec") }
    }
}

extension ZcashNamesTests {
    private final class StubZnsResolver: ZnsResolver {
        private let address: String?
        private let error: Error?
        private(set) var queries = [String]()

        init(address: String?) {
            self.address = address
            error = nil
            super.init(networkManager: NetworkManager())
        }

        init(error: Error) {
            address = nil
            self.error = error
            super.init(networkManager: NetworkManager())
        }

        override func resolve(name: String) async throws -> String? {
            queries.append(name)

            if let error {
                throw error
            }

            return address
        }
    }

    private static let thebackupkidAddress = "u19qfnukkpz06w60e7wmgfqv4l0xeyyaprtz59fulemxk0527xnuyewp8gqck3f2kljq29hw7dz8f595pyt5yns5lz6cvyczn2ky7uwplfdkl4m2kgr5ljuam4m3l6mpvdklcut3640txl6z0xduk0lnsqv2zagatlc4extw8j2zyx8829enfkd72xu2r3kt4qrapfty0cttrzyc52ak9"
    private static let zechariahAddress = "u14lms6q2sg984hhng068lqesatnak86mlg297x0qkqsvkqgk2m7dyj5x2grlku3adg2tq6trl5ue3vce7c3jnu5808kw9lsr890kfetrg524q4pgcn4zcnp84na85453pz67cjfy4sx7y6z6zc9t7666utasw5mehe9r2dwwcrgzp94ah"

    // zcashnames.com/docs/resolver/verifying-state, 2026-10-23
    private static let publishedMainnetViewingKey = "uview1209ld9y4fr2sel9q87kfjg7xm2sy53e3qf7dvcw3w8jwhhjpldl8z0vk0a6hveg4jk7xcn0rc9mr8yg77djfpc0uxrm5pqzt8q7ul4w0nvs3x5q9vmk9nm2crywtqaealek4mp47ur7ywu7g4g4xcdlwv6gnqzvu5panv5je2ps6rxmx4856unlt5wde8fpz8uhrqchmwhn2j252h3cyx5phad877xezerm6ex8l5kcfjw02ll7m0nspfufamh3ae9ea48395elptspnv6vvc70j2gcjrdze9syt8kpr2kc67flvg8687thdkpha7lpt9r4p9wjty90q2v2yjanqsr2zrecrqs7lfx9cpkmshf7jyh2vvwfqnyzwtpuy7p72hm2mjhperdafvm9u5rwa6s6urcy0uw30f687e3jnmas45qfqtwyz39kf6kxklfrdn7t4hkz56jegmlr8s8hwmt9wa8vz8zlmm76lrmzyj82nzpeqfu572njq"
    private static let testnetViewingKey = "uviewtest1gkq78nsemsvs4qekadrv6qlqdmvcv2cct8k3c8cwycedpk90p8rtkx24qe8q73gg2ark8crqmmaavrerf7cxu0sp50an54crmeaalfxl72aetxnr89ksad4lvxzmnkyejhhwn65euzamt9wsukgfemeayhcesreasarmq600lfeju3qenh05e5e5cz6nhhsw3cfdcd3d08d0nxswxmkkxl2fq0hzv6t5dm3ftnz4y76236a49v3us4uq2tlsewf86tjtfwm6kue348me04rm7dw6uawv8myw7t5tyx2t453clhjz5f55lvh7hnvr8g8zt8lf4sy5rzq23ntp7g5ly6kyz2nkwfek06llhjtuz2fft9rg6cuuwg4n7299vajnmq6swg3sf563r0jjzuwuvfpjhmfmydar9dcu3fkuawt6u8qu08vhg5mthrcggrjuhht6f0perh0tqmdfrtgzvhjymay7h9ymvfxgd4r56uz6zrsf5gnvw5jy"

    // verbatim mainnet responses, 2026-10-23
    private static let thebackupkidBody = #"{"jsonrpc":"2.0","id":1,"result":{"name":"thebackupkid","address":"\#(thebackupkidAddress)","txid":"fedc19a5dd139eb3eaea275163c5671abd13c709e696f2be2a8ff2dd8f73025c","height":3520312,"last_action":"claim","expires_at":"none"}}"#
    private static let zechariahBody = #"{"jsonrpc":"2.0","id":1,"result":{"name":"zechariah","address":"\#(zechariahAddress)","txid":"ed98bed2e92ac46f16b27db5c55597539abc714fb259f1bc2b2fa5dfb586e266","height":3523662,"last_action":"claim","expires_at":"1824002006"}}"#
    private static let statusBody = #"{"jsonrpc":"2.0","id":1,"result":{"synced_height":3527534,"synced":true,"viewing_key":"\#(publishedMainnetViewingKey)","treasury_address":"u1f68wxdxsrswjl04kcc397a9ljedg88rl8dgazrk8l9v8jx6t3gqsktvqyvmc3ypgf4pum03q4ftvy5s0fe803nrxm8kw6dgzlvnv83nv"}}"#

    private func name(_ input: String) -> String? {
        ZnsAddressParserItem.normalize(input)?.name
    }

    private func json(_ body: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(body.utf8), options: [.fragmentsAllowed])
    }

    private func registration(_ body: String) throws -> ZnsResolver.Registration? {
        let json = try json(body)
        return try ZnsResolver.registration(json: json)
    }

    private func kind(_ error: ZnsResolver.ResolveError) -> String {
        switch error {
        case .rpcError: return "rpcError"
        case .malformedResponse: return "malformedResponse"
        case .unknownRegistry: return "unknownRegistry"
        case .nameMismatch: return "nameMismatch"
        }
    }

    private func expectRpcError(_ error: ZnsResolver.ResolveError?, code: Int, message: String) {
        guard case let .rpcError(actualCode, actualMessage)? = error else {
            Issue.record("expected rpcError, got \(String(describing: error))")
            return
        }

        #expect(actualCode == code)
        #expect(actualMessage == message)
    }

    private func zcashParserItem() -> ZcashAddressParserItem {
        let validator = ZcashAddressValidator(network: ZcashNetworkBuilder.network(for: .mainnet))
        return ZcashAddressParserItem(parserType: .validator(validator), addressType: nil)
    }

    private func isValid(_ item: IAddressParserItem, _ address: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.isValid(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }

    private func handle(_ item: IAddressParserItem, _ address: String) async throws -> Address {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.handle(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }
}
