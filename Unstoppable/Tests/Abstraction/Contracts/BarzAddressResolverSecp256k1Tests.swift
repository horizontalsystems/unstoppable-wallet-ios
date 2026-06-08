import BigInt
import EvmKit
import HdWalletKit
import HsCryptoKit
import HsExtensions
import HsToolKit
import MarketKit
@testable import Unstoppable
@testable import WalletCore
import XCTest

/// Tests for BarzAddressResolver with curve = .secp256k1.
///
/// Structural + mocked tests run in CI (always green).
/// Live Q2/Q3 verification (local CREATE2 vs on-chain factory.getAddress) is
/// gated by BARZ_LIVE_TESTS=1 env var — opt-in because it hits public RPC.
///
/// See `docs/superpowers/spikes/2026-04-29-pr-a1-signer-and-create2-spike.md`
/// for Q2/Q3 verification framing.
final class BarzAddressResolverSecp256k1Tests: XCTestCase {
    private let testX = Data(repeating: 0x11, count: 32)
    private let testY = Data(repeating: 0x22, count: 32)

    // MARK: - Structural

    func testResolveLocallyIsDeterministicForSameInput() throws {
        let address1 = try BarzAddressResolver.resolveLocally(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .ethereum
        )
        let address2 = try BarzAddressResolver.resolveLocally(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .ethereum
        )

        XCTAssertEqual(address1, address2)
    }

    /// secp256k1 path uses a different VerificationFacet AND encodes owner as 20-byte EOA
    /// (vs 65-byte uncompressed pubkey for secp256r1). Both differences enter the CREATE2
    /// bytecode hash, so addresses MUST differ for the same X/Y.
    func testResolveLocallyDiffersFromSecp256r1ForSameXY() throws {
        let secp256k1 = try BarzAddressResolver.resolveLocally(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .ethereum
        )
        let secp256r1 = try BarzAddressResolver.resolveLocally(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256r1,
            blockchainType: .ethereum
        )

        XCTAssertNotEqual(secp256k1, secp256r1)
    }

    /// Trust Wallet deployed Secp256k1VerificationFacet at different addresses on
    /// Mainnet (0x58Cb9Abe…) and BSC (0x81b9E3…). Since the facet address enters
    /// the CREATE2 bytecode hash via constructor args, AA addresses MUST differ
    /// between Mainnet and BSC for the same owner.
    func testResolveLocallyDiffersBetweenMainnetAndBsc() throws {
        let mainnet = try BarzAddressResolver.resolveLocally(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .ethereum
        )
        let bsc = try BarzAddressResolver.resolveLocally(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .binanceSmartChain
        )

        XCTAssertNotEqual(mainnet, bsc, "Different facet addresses → different CREATE2 results")
    }

    func testResolveLocallyUnsupportedChainThrows() {
        XCTAssertThrowsError(
            try BarzAddressResolver.resolveLocally(
                publicKeyX: testX,
                publicKeyY: testY,
                curve: .secp256k1,
                blockchainType: .polygon
            )
        )
    }

    // MARK: - Mocked wire encoding

    /// Verifies that resolveViaFactory with curve=.secp256k1 sends the correct calldata
    /// to BarzFactory.getAddress on Mainnet — including the Mainnet-specific facet address.
    func testResolveViaFactorySecp256k1_usesEthereumFacetInCallData() async throws {
        let mainnetFacetHex = "58cb9abe27fcd6f72354e98cf5cc46beaa2182df"

        let address = try await BarzAddressResolver.resolveViaFactory(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .ethereum,
            salt: 0,
            call: { contractAddress, data in
                XCTAssertEqual(contractAddress, ChainAddresses.barzFactory)
                XCTAssertTrue(
                    data.hs.hex.contains(mainnetFacetHex),
                    "calldata must reference Mainnet Secp256k1VerificationFacet (0x58Cb9Abe…)"
                )
                return Data("0000000000000000000000001234567890abcdef1234567890abcdef12345678".hs.hexData!)
            }
        )

        XCTAssertEqual(address, try EvmKit.Address(hex: "0x1234567890abcdef1234567890abcdef12345678"))
    }

    func testResolveViaFactorySecp256k1_usesBscFacetInCallData() async throws {
        let bscFacetHex = "81b9e3689390c7e74cf526594a105dea21a8cdd5"

        _ = try await BarzAddressResolver.resolveViaFactory(
            publicKeyX: testX,
            publicKeyY: testY,
            curve: .secp256k1,
            blockchainType: .binanceSmartChain,
            salt: 0,
            call: { _, data in
                XCTAssertTrue(
                    data.hs.hex.contains(bscFacetHex),
                    "calldata must reference BSC Secp256k1VerificationFacet (0x81b9E3…)"
                )
                return Data("0000000000000000000000001234567890abcdef1234567890abcdef12345678".hs.hexData!)
            }
        )
    }

    // MARK: - Live Q2/Q3 (opt-in via BARZ_LIVE_TESTS=1)

    /// Q2 — verifies that local CREATE2 derivation matches BarzFactory.getAddress
    /// on Mainnet for the hardhat test mnemonic's secp256k1 EOA.
    /// Run with: `BARZ_LIVE_TESTS=1 xcodebuild test ...`
    func testQ2_resolveLocallyMatchesFactoryOnEthereum() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BARZ_LIVE_TESTS"] == "1",
            "Live RPC test. Set BARZ_LIVE_TESTS=1 env var to run."
        )

        let (X, Y) = try Self.hardhatPubkeyHalves()

        let local = try BarzAddressResolver.resolveLocally(
            publicKeyX: X,
            publicKeyY: Y,
            curve: .secp256k1,
            blockchainType: .ethereum
        )
        let onChain = try await BarzAddressResolver.resolveViaFactory(
            publicKeyX: X,
            publicKeyY: Y,
            curve: .secp256k1,
            blockchainType: .ethereum,
            networkManager: NetworkManager(),
            rpcSource: .http(urls: [URL(string: "https://ethereum-rpc.publicnode.com")!], auth: nil)
        )

        XCTAssertEqual(local, onChain, "Local CREATE2 must match factory.getAddress on Mainnet (Q2)")
    }

    /// Q3 — same as Q2 but for BSC. Different facet address → different AA address.
    /// If both Q2 and Q3 pass, our local CREATE2 is correct on both chains.
    func testQ3_resolveLocallyMatchesFactoryOnBsc() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BARZ_LIVE_TESTS"] == "1",
            "Live RPC test. Set BARZ_LIVE_TESTS=1 env var to run."
        )

        let (X, Y) = try Self.hardhatPubkeyHalves()

        let local = try BarzAddressResolver.resolveLocally(
            publicKeyX: X,
            publicKeyY: Y,
            curve: .secp256k1,
            blockchainType: .binanceSmartChain
        )
        let onChain = try await BarzAddressResolver.resolveViaFactory(
            publicKeyX: X,
            publicKeyY: Y,
            curve: .secp256k1,
            blockchainType: .binanceSmartChain,
            networkManager: NetworkManager(),
            rpcSource: .binanceSmartChainHttp()
        )

        XCTAssertEqual(local, onChain, "Local CREATE2 must match factory.getAddress on BSC (Q3)")
    }

    // MARK: - Helpers

    private static func hardhatPubkeyHalves() throws -> (Data, Data) {
        let mnemonic = [
            "test", "test", "test", "test", "test", "test",
            "test", "test", "test", "test", "test", "junk",
        ]
        let seed = try XCTUnwrap(Mnemonic.seed(mnemonic: mnemonic, passphrase: ""))
        let privateKey = try Signer.privateKey(seed: seed, chain: .ethereum)
        let pubkey = Crypto.publicKey(privateKey: privateKey, compressed: false)
        return (Data(pubkey.dropFirst().prefix(32)), Data(pubkey.dropFirst().suffix(32)))
    }
}
