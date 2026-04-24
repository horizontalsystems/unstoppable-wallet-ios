import BigInt
import EvmKit
import HsExtensions
import MarketKit
@testable import Unstoppable
import XCTest

final class BarzAddressResolverTests: XCTestCase {
    func testResolveLocallyMatchesFactoryFixture() throws {
        let address = try BarzAddressResolver.resolveLocally(
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32),
            blockchainType: .ethereum
        )

        XCTAssertEqual(address, try EvmKit.Address(hex: "0x9eab247c9c7406b1bb38a972730ce18c40046d30"))
    }

    func testResolveViaFactoryUsesEthCallResponse() async throws {
        let address = try await BarzAddressResolver.resolveViaFactory(
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32),
            blockchainType: .ethereum,
            salt: 0,
            call: { contractAddress, data in
                XCTAssertEqual(contractAddress, ChainAddresses.barzFactory)
                XCTAssertEqual(
                    data.hs.hex,
                    "c8a7adf5000000000000000000000000ee1af8e967ec04c84711842796a5e714d2fd33e6000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041041111111111111111111111111111111111111111111111111111111111111111222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000"
                )
                return Data("0000000000000000000000009eab247c9c7406b1bb38a972730ce18c40046d30".hs.hexData!)
            }
        )

        XCTAssertEqual(address, try EvmKit.Address(hex: "0x9eab247c9c7406b1bb38a972730ce18c40046d30"))
    }

    func testResolveLocallyUnsupportedChainThrows() {
        XCTAssertThrowsError(
            try BarzAddressResolver.resolveLocally(
                publicKeyX: Data(repeating: 0x11, count: 32),
                publicKeyY: Data(repeating: 0x22, count: 32),
                blockchainType: .polygon
            )
        )
    }
}
