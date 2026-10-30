import Foundation
import RxSwift
import Testing
@testable import WalletCore

/// Android AddressHandlerNear + NearAddressValidator: which inputs are NEAR accounts, and that only a
/// definite "no" from the node refuses a name. With no RPC endpoint the node never answers, so these
/// run offline; a missing name being refused needs the network (manual checklist, spec §10.4 A3).
struct NearAddressParserItemTests {
    private static let implicit = "98793cd91a3f870fb126f66285808c7e094afcfc4eda8a970f6648cdf0dbd6de"
    private static let ethImplicit = "0xa9e3026b727f15f3c3cdaa931e3c56955086513f"

    private let item = NearAddressParserItem(rpcUrls: [])

    @Test func recognizesNearAccounts() async throws {
        let implicit = try await isValid(Self.implicit)
        let ethImplicit = try await isValid(Self.ethImplicit)
        let named = try await isValid("alice.near")
        // a bare word is a valid id but also any word, a deterministic 0s… account cannot be sent to
        let bareWord = try await isValid("alice")
        let deterministic = try await isValid("0s" + String(repeating: "a", count: 40))
        let malformed = try await isValid("Alice..near")

        #expect(implicit && ethImplicit && named)
        #expect(!bareWord && !deterministic && !malformed)
    }

    /// the first transfer creates an implicit account: nothing to ask the node
    @Test func implicitAccountIsAccepted() async throws {
        let implicit = try await handle(Self.implicit)
        let ethImplicit = try await handle(Self.ethImplicit)

        #expect(implicit.raw == Self.implicit)
        #expect(ethImplicit.raw == Self.ethImplicit)
    }

    /// the node did not answer: a blip while typing must not reject a well-formed name
    @Test func unansweredLookupLetsANameThrough() async throws {
        let named = try await handle("alice.near")

        #expect(named.raw == "alice.near")
    }

    @Test func malformedIdIsRefused() async {
        await #expect(throws: (any Error).self) { try await handle("Alice..near") }
    }

    private func isValid(_ address: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.isValid(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }

    private func handle(_ address: String) async throws -> Address {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.handle(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }
}
