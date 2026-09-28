import CryptoKit
import Foundation
import HsToolKit
import MarketKit
import RxSwift
import Testing
@testable import WalletCore
import ZcashLightClientKit

// Zcash Names: the cases of Android ZnsTest on the same live mainnet vectors, plus the edges of the Swift port.
struct ZcashNamesTests {
    // MARK: - Name normalization

    @Test func normalizeAcceptsBothSuffixesInAnyCase() {
        #expect(name("alice.zcash") == "alice")
        #expect(name("alice.zec") == "alice")
        #expect(name("Alice.ZCASH") == "alice")
        #expect(name("aLice.Zec") == "alice")
        #expect(name("  alice.zcash \n") == "alice")
        #expect(name("bob42.zec") == "bob42")
        #expect(name("a.zcash") == "a")
        #expect(name(String(repeating: "a", count: 62) + ".zcash") == String(repeating: "a", count: 62))
    }

    @Test func normalizeKeepsTheTypedSuffix() {
        #expect(ZnsAddressParserItem.normalize("Alice.ZEC")?.suffix == ".zec")
        #expect(ZnsAddressParserItem.normalize("alice.zcash")?.suffix == ".zcash")
    }

    // the suffix is required: a bare word is indistinguishable from a partly typed address
    @Test func normalizeRejectsBareNamesAndAddresses() {
        #expect(name("alice") == nil)
        #expect(name("childish") == nil)
        #expect(name("u1jlu75mjtmhdekpq0nx5kakkgdnss8ta6xqzwu8p278axz0zt3pmep8hs4u0ws0nhlz") == nil)
        #expect(name("t1RBzFrCTWSZe3FJbDewtveUMRX2og4kKph") == nil)
        #expect(name("zs1abc") == nil)
    }

    @Test func normalizeRejectsInvalidNames() {
        #expect(name("") == nil)
        #expect(name(".zcash") == nil)
        #expect(name("my-name.zcash") == nil)
        #expect(name("my_name.zec") == nil)
        #expect(name("has space.zcash") == nil)
        #expect(name("café.zcash") == nil)
        #expect(name("alice.zcash.zcash") == nil)
        #expect(name("alice.eth") == nil)
        #expect(name(String(repeating: "a", count: 63) + ".zcash") == nil)
        // `$` in a regex also matches before a final line break; the name must end at the suffix
        #expect(name("alice\n.zcash") == nil)
    }

    // as on Android: Unicode lowercasing folds the Kelvin sign into an ASCII "k"
    @Test func normalizeFoldsKelvinSignLikeAndroid() {
        #expect(name("\u{212A}im.zcash") == "kim")
    }

    // MARK: - Response parsing

    @Test func parseFoundRegistration() throws {
        let registration = try #require(try ZnsResolver.registration(json: json(Self.childishBody)))

        #expect(registration.name == "childish")
        #expect(registration.address == Self.childishAddress)
        #expect(registration.nonce == 0)
        #expect(registration.lastAction == "BUY")
        #expect(registration.signature == Self.childishSignature)
        #expect(registration.pubkey == nil)
    }

    @Test func parseNotRegistered() throws {
        #expect(try ZnsResolver.registration(json: json(#"{"jsonrpc":"2.0","id":1,"result":null}"#)) == nil)
    }

    @Test func parseRpcError() throws {
        let body = #"{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid params"}}"#

        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.registration(json: json(body)) }
    }

    // the indexer answers an address query with an array; a name query never should
    @Test func parseRejectsArrayResult() throws {
        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.registration(json: json(#"{"jsonrpc":"2.0","id":1,"result":[]}"#)) }
    }

    @Test func parseRejectsMissingFields() throws {
        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.registration(json: json(#"{"jsonrpc":"2.0","id":1,"result":{"name":"alice"}}"#)) }
        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.registration(json: json(#"{"jsonrpc":"2.0","id":1}"#)) }
    }

    @Test func parseRejectsMalformedBodies() {
        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.registration(json: [Any]()) }
        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.registration(json: "not json") }
    }

    // the indexer controls the nonce; anything but a whole non-negative number is refused, never trapped on
    @Test func parseRejectsNoncesThatAreNotWholeNonNegativeNumbers() throws {
        for nonce in ["-1", "1.5", "true", "\"2\"", "-9223372036854775808"] {
            #expect(throws: ZnsResolver.ResolveError.self, "nonce \(nonce)") { try ZnsResolver.registration(json: json(registrationBody(nonce: nonce))) }
        }

        #expect(try ZnsResolver.registration(json: json(registrationBody(nonce: "9223372036854775807")))?.nonce == Int64.max)
    }

    // MARK: - Pre-image

    @Test func preImageFollowsLastAction() {
        let base = registration(name: "alice", address: "u1example", nonce: 2, lastAction: "CLAIM")

        #expect(ZnsResolver.preImage(registration: base, nonce: 2) == "CLAIM:alice:u1example")
        #expect(ZnsResolver.preImage(registration: with(base, lastAction: "BUY"), nonce: 2) == "BUY:alice:u1example")
        #expect(ZnsResolver.preImage(registration: with(base, lastAction: "UPDATE"), nonce: 2) == "UPDATE:alice:u1example:2")
        // DELIST:{name}:{nonce} does not cover the address, so it cannot authenticate one
        #expect(ZnsResolver.preImage(registration: with(base, lastAction: "DELIST"), nonce: 2) == nil)
        #expect(ZnsResolver.preImage(registration: with(base, lastAction: "LIST"), nonce: 2) == nil)
        #expect(ZnsResolver.preImage(registration: with(base, lastAction: "RELEASE"), nonce: 2) == nil)
    }

    // MARK: - Validation

    @Test func validateReturnsAddressOfMatchingVerifiedRegistration() throws {
        let registration = try childish()

        #expect(try ZnsResolver.validate(name: "childish", registration: registration) == Self.childishAddress)
    }

    // a replayed registration of another name is validly signed but must not answer this query
    @Test func validateRejectsRegistrationOfAnotherName() throws {
        let registration = try childish()

        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.validate(name: "alice", registration: registration) }
    }

    @Test func validateRejectsInvalidSignature() throws {
        let registration = try with(childish(), nonce: 5, lastAction: "UPDATE")

        #expect(throws: ZnsResolver.ResolveError.self) { try ZnsResolver.validate(name: "childish", registration: registration) }
    }

    // MARK: - Signature verification (live mainnet vectors)

    @Test func pinnedRegistrarKeyIsValid() {
        #expect(ZnsResolver.adminKey.rawRepresentation.count == 32)
    }

    @Test func verifiesBuyRegistration() throws {
        #expect(try ZnsResolver.verify(registration: childish()))
    }

    @Test func verifiesClaimRegistrations() {
        let gaurang = registration(
            name: "gaurang",
            address: "u1h743e3e4kstgsddvw6ngu8kpntj34keprem8jm3x5tjh47d4g6kg78x4chy444l5mj2xetpnacml6xv4alsm6vwlsvqlrmkjfqza04lxjzm7ctnr6mzh2kmeqqel235mc660uy3a7cjx85vv5l43gl365xhlywe2zeptkppdkk8kqlhpdlaa09d54jgphqugxledqp9syfu9g7qx8ta",
            nonce: 0,
            lastAction: "CLAIM",
            signature: "VL7SIbtmGGCCKPBNV4XnYMAvV6I6qwvXvKV+KY5VIY65JlSVb1+95mrjuUeiIEyWcu2TPGmUj6m+bvNOkI6zDA=="
        )
        let tom = registration(
            name: "tom",
            address: "u166d7d9zxr0r47n3wd8s9g3w62l7t0yd7vt6kgagacz5gjewrd97x7hcr8vsln4f6qs8tu5a9srtyl2cf2uc4rf5p6qkkrlmtferggcmr9wrf9nd3hjsamsrr9dh4qu7vnrlkd9wgxmgnv45mwmsfu5gj3c0vy0304utrhdl6rkx9c8f5mh49hg8lwl6clcavy9xk74nuq8zh5pq86se",
            nonce: 0,
            lastAction: "CLAIM",
            signature: "qNmxD19MDWiCBIL8aOTTrKmCb4alZ4H+jzu7dK105szAURJdCji9MyVPnFoKuoWwtupBxYG0iKnMF4XRxZyxAQ=="
        )

        #expect(ZnsResolver.verify(registration: gaurang))
        #expect(ZnsResolver.verify(registration: tom))
    }

    // zechariah: CLAIM (nonce 0), UPDATE signed with nonce 1, then a LIST raised the registry nonce to 2 without
    // touching last_action or signature. The reported nonce does not verify; the walk finds the signed one.
    @Test func verifiesUpdateSignedWithEarlierNonce() {
        let zechariah = registration(
            name: "zechariah",
            address: "u14lms6q2sg984hhng068lqesatnak86mlg297x0qkqsvkqgk2m7dyj5x2grlku3adg2tq6trl5ue3vce7c3jnu5808kw9lsr890kfetrg524q4pgcn4zcnp84na85453pz67cjfy4sx7y6z6zc9t7666utasw5mehe9r2dwwcrgzp94ah",
            nonce: 2,
            lastAction: "UPDATE",
            signature: "0yNPmGqCQGIMYXOXLmpXRSrOo1B1FWDgpvU1jHrqzvFYz9ZLitNeKB93ANVwpmkU/KD/R6OHK0x9MWIpBDB1BQ=="
        )

        #expect(ZnsResolver.verify(registration: zechariah))
        #expect(ZnsResolver.verify(registration: with(zechariah, nonce: 1)))
        // the walk only goes down, so a reported nonce below the signed one fails
        #expect(!ZnsResolver.verify(registration: with(zechariah, nonce: 0)))
        // CLAIM and BUY do not use the nonce, so there is no walk for them
        #expect(!ZnsResolver.verify(registration: with(zechariah, lastAction: "CLAIM")))
    }

    @Test func nonceWalkStopsAtSearchDepth() throws {
        let key = Curve25519.Signing.PrivateKey()
        let reported: Int64 = 100

        #expect(try ZnsResolver.verify(registration: signedUpdate(key: key, signedNonce: reported - ZnsResolver.nonceSearchDepth, reportedNonce: reported), adminKey: key.publicKey))
        #expect(try !ZnsResolver.verify(registration: signedUpdate(key: key, signedNonce: reported - ZnsResolver.nonceSearchDepth - 1, reportedNonce: reported), adminKey: key.publicKey))
    }

    @Test func extremeNoncesNeverTrap() throws {
        let key = Curve25519.Signing.PrivateKey()

        #expect(try !ZnsResolver.verify(registration: signedUpdate(key: key, signedNonce: 0, reportedNonce: Int64.max), adminKey: key.publicKey))
        #expect(try !ZnsResolver.verify(registration: signedUpdate(key: key, signedNonce: 0, reportedNonce: Int64.min), adminKey: key.publicKey))
        #expect(try !ZnsResolver.verify(registration: signedUpdate(key: key, signedNonce: 0, reportedNonce: -1), adminKey: key.publicKey))
    }

    @Test func rejectsTamperedAddress() throws {
        let registration = try childish()

        #expect(!ZnsResolver.verify(registration: with(registration, address: String(registration.address.dropLast()) + "h")))
    }

    @Test func rejectsTamperedSignatureAndWrongKey() throws {
        let registration = try childish()

        #expect(!ZnsResolver.verify(registration: with(registration, signature: "A" + Self.childishSignature.dropFirst())))
        #expect(!ZnsResolver.verify(registration: registration, adminKey: Curve25519.Signing.PrivateKey().publicKey))
    }

    @Test func rejectsMissingSignatureAndActionsThatDoNotCoverTheAddress() throws {
        let registration = try childish()

        #expect(!ZnsResolver.verify(registration: with(registration, signature: .some(nil))))
        #expect(!ZnsResolver.verify(registration: with(registration, signature: "")))
        #expect(!ZnsResolver.verify(registration: with(registration, signature: "not base64!")))
        #expect(!ZnsResolver.verify(registration: with(registration, signature: String(Self.childishSignature.dropLast(4)))))
        #expect(!ZnsResolver.verify(registration: with(registration, lastAction: "DELIST")))
        #expect(!ZnsResolver.verify(registration: with(registration, lastAction: "RELEASE")))
    }

    // the attached key comes from the same response, so a registration carrying one is never accepted
    @Test func rejectsSovereignRegistrations() throws {
        let registration = try childish()
        let adminKey = ZnsResolver.adminKey.rawRepresentation.base64EncodedString()

        #expect(!ZnsResolver.verify(registration: with(registration, pubkey: adminKey)))
        #expect(!ZnsResolver.verify(registration: with(registration, pubkey: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")))
    }

    // MARK: - Parser item

    @Test func parserItemTakesOnlyNames() async throws {
        let item = parserItem(url: "http://127.0.0.1:1")

        let name = try await isValid(item, "alice.zcash")
        let bareWord = try await isValid(item, "alice")
        let address = try await isValid(item, "u1jlu75mjtmhdekpq0nx5kakkgdnss8ta6xqzwu8p278axz0zt3pmep8hs4u0ws0nhlz")

        #expect(name)
        #expect(!bareWord)
        #expect(!address)
    }

    @Test func unreachableResolverIsAnInvalidAddress() async {
        let item = parserItem(url: "http://127.0.0.1:1")

        await #expect(throws: AddressService.AddressError.self) { try await handle(item, "alice.zcash") }
    }
}

extension ZcashNamesTests {
    private static let childishAddress = "u1jlu75mjtmhdekpq0nx5kakkgdnss8ta6xqzwu8p278axz0zt3pmep8hs4u0ws0nhlz40925lq770cqw8thnzyp2upm6vwxsc6rrfr3zuvrnjtkrayf9lm09fv3v2erhnu7jme34w2c5x47eafzkks2mwfegphd6aa0dsp0qtxy382nrg"
    private static let childishSignature = "9ChHKUP7I+j2KKB4WARAayqWY4ZA6pX7cDwKuuGJOVBypAPxXOlUITrC7+B0gekJfN8Zv2Na1Aa+Og/W3qb0AQ=="

    // verbatim mainnet response for resolve {"query":"childish"}
    private static let childishBody = #"{"jsonrpc":"2.0","id":1,"result":{"address":"\#(childishAddress)","height":3476168,"last_action":"BUY","listing":null,"name":"childish","nonce":0,"signature":"\#(childishSignature)","txid":"8eecefa29c32c9adbc2a0d72d59c7163dd6c744f43c7178caa77d2788dce6e8f"}}"#

    private func name(_ input: String) -> String? {
        ZnsAddressParserItem.normalize(input)?.name
    }

    private func json(_ body: String) throws -> Any {
        try JSONSerialization.jsonObject(with: Data(body.utf8), options: [.fragmentsAllowed])
    }

    private func registrationBody(nonce: String) -> String {
        #"{"jsonrpc":"2.0","id":1,"result":{"address":"u1example","last_action":"UPDATE","name":"alice","nonce":\#(nonce),"signature":null}}"#
    }

    private func childish() throws -> ZnsResolver.Registration {
        try #require(try ZnsResolver.registration(json: json(Self.childishBody)))
    }

    private func registration(name: String, address: String, nonce: Int64, lastAction: String, signature: String? = "AQID", pubkey: String? = nil) -> ZnsResolver.Registration {
        ZnsResolver.Registration(name: name, address: address, nonce: nonce, lastAction: lastAction, signature: signature, pubkey: pubkey)
    }

    private func with(
        _ registration: ZnsResolver.Registration,
        address: String? = nil,
        nonce: Int64? = nil,
        lastAction: String? = nil,
        signature: String?? = nil,
        pubkey: String?? = nil
    ) -> ZnsResolver.Registration {
        ZnsResolver.Registration(
            name: registration.name,
            address: address ?? registration.address,
            nonce: nonce ?? registration.nonce,
            lastAction: lastAction ?? registration.lastAction,
            signature: signature ?? registration.signature,
            pubkey: pubkey ?? registration.pubkey
        )
    }

    private func signedUpdate(key: Curve25519.Signing.PrivateKey, signedNonce: Int64, reportedNonce: Int64) throws -> ZnsResolver.Registration {
        let signature = try key.signature(for: Data("UPDATE:alice:u1example:\(signedNonce)".utf8))
        return registration(name: "alice", address: "u1example", nonce: reportedNonce, lastAction: "UPDATE", signature: signature.base64EncodedString())
    }

    private func parserItem(url: String) -> ZnsAddressParserItem {
        let validator = ZcashAddressValidator(network: ZcashNetworkBuilder.network(for: .mainnet))
        let zcashParserItem = ZcashAddressParserItem(parserType: .validator(validator), addressType: nil)
        return ZnsAddressParserItem(resolver: ZnsResolver(networkManager: NetworkManager(), url: url), rawAddressParserItem: zcashParserItem)
    }

    private func isValid(_ item: ZnsAddressParserItem, _ address: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.isValid(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }

    private func handle(_ item: ZnsAddressParserItem, _ address: String) async throws -> Address {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.handle(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }
}
