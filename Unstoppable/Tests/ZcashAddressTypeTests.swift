import Testing
@testable import WalletCore
import ZcashLightClientKit

// #7295: a TEX address (ZIP 320) is a transparent P2PKH address in Bech32m, so a send to it is a transparent output
// and carries no memo. ZcashPreSendHandler.memoType(address:) reads this type, so the send form shows no memo field
// for it, as Android does (AddressType.Tex -> Transparent)
struct ZcashAddressTypeTests {
    // ZIP 320's reference pair: the same key hash as a TEX address and as a t-address
    private static let tex = "tex1s2rt77ggv6q989lr49rkgzmh5slsksa9khdgte"
    private static let transparent = "t1VmmGiyjVNeCjxDZzg7vZmd99WyzVby9yC"

    @Test(arguments: [tex, transparent])
    func transparentReceiverIsTransparent(address: String) throws {
        #expect(try addressType(address) == .transparent)
    }

    @Test func saplingIsShielded() throws {
        #expect(try addressType(AddressUriFixtures.zecShielded) == .shielded)
    }

    private func addressType(_ address: String) throws -> ZcashAdapter.AddressType {
        try ZcashAdapter.addressType(recipient: Recipient(address, network: .mainnet))
    }
}
