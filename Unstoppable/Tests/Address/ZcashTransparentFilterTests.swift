import MarketKit
import RxSwift
import Testing
@testable import WalletCore
import ZcashLightClientKit

// The transparent-only parser filter behind a ZEC swap recipient on a route that cannot pay a shielded
// receiver (spec 2026-10-16): transparent addresses pass; shielded and unified ones are recognised as
// Zcash addresses and refused with the filter's own reason, which the form shows under "Invalid Address"
struct ZcashTransparentFilterTests {
    private static let transparent = "t1RBzFrCTWSZe3FJbDewtveUMRX2og4kKph"
    // ZIP 320 example: the TEX form of t1VmmGiyjVNeCjxDZzg7vZmd99WyzVby9yC
    private static let tex = "tex1s2rt77ggv6q989lr49rkgzmh5slsksa9khdgte"
    private static let unified = "u1pg2aaph7jp8rpf6yhsza25722sg5fcn3vaca6ze27hqjw7jvvhhuxkpcg0ge9xh6drsgdkda8qjq5chpehkcpxf87rnjryjqwymdheptpvnljqqrjqzjwkc2ma6hcq666kgwfytxwac8eyex6ndgr6ezte66706e3vaqrd25dzvzkc69kw0jgywtd0cmq52q5lkw6uh7hyvzjse8ksx"

    @Test(arguments: [transparent, tex])
    func transparentOnlyAcceptsTransparent(address: String) async throws {
        let item = parserItem(addressType: .transparent)
        let valid = try await isValid(item, address)
        let handled = try await handle(item, address)
        #expect(valid)
        #expect(handled.raw == address)
    }

    // a TEX address is a transparent receiver (ZIP 320), so neither the filter nor the memo field may
    // treat it as shielded (#7295)
    @Test func texIsTransparent() throws {
        let recipient = try Recipient(Self.tex, network: .mainnet)
        #expect(recipient.isTransparent)
        #expect(!(try Recipient(Self.unified, network: .mainnet)).isTransparent)
    }

    @Test(arguments: [unified, AddressUriFixtures.zecShielded])
    func transparentOnlyRefusesShieldedWithReason(address: String) async throws {
        let item = parserItem(addressType: .transparent)
        let valid = try await isValid(item, address)
        #expect(valid)
        await #expect(throws: ZcashAddressParserItem.ParseError.onlyTransparent) {
            try await handle(item, address)
        }
    }

    // the chain hands the address to the Zcash parser and passes its reason on, so the form can show it
    @Test func chainPassesTheFilterReasonOn() async throws {
        let chain = AddressParserChain().append(handler: parserItem(addressType: .transparent))

        do {
            _ = try await handle(chain, Self.unified)
            Issue.record("expected the filter reason")
        } catch let AddressParserChain.ParserError.fetchError(error) {
            #expect(error as? ZcashAddressParserItem.ParseError == .onlyTransparent)
            #expect(error.localizedDescription == "swap.recipient.error.transparent_zcash_required".localized)
        }
    }

    // the shielded fixtures are valid on their own, so a refusal above comes from the filter, not the validator
    @Test(arguments: [unified, AddressUriFixtures.zecShielded])
    func unfilteredAcceptsShielded(address: String) async throws {
        let item = parserItem(addressType: nil)
        let handled = try await handle(item, address)
        #expect(handled.raw == address)
    }

    private func parserItem(addressType: ZcashAdapter.AddressType?) -> ZcashAddressParserItem {
        let validator = ZcashAddressValidator(network: ZcashNetworkBuilder.network(for: .mainnet))
        return ZcashAddressParserItem(parserType: .validator(validator), addressType: addressType)
    }

    private func isValid(_ item: ZcashAddressParserItem, _ address: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.isValid(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }

    @discardableResult
    private func handle(_ item: ZcashAddressParserItem, _ address: String) async throws -> Address {
        try await withCheckedThrowingContinuation { continuation in
            _ = item.handle(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }

    private func handle(_ chain: AddressParserChain, _ address: String) async throws -> Address? {
        try await withCheckedThrowingContinuation { continuation in
            _ = chain.handle(address: address).subscribe(onSuccess: { continuation.resume(returning: $0) }, onError: { continuation.resume(throwing: $0) })
        }
    }
}
