import Testing
import TronKit
@testable import Unstoppable

struct GasFreeAddressResolverTests {
    @Test func mainnetVectorMatchesUpstreamSDK() throws {
        let vector = GasFreeFixtures.AddressDerivation.mainnetExample
        let userAddress = try TronKit.Address(address: vector.userAddress)

        let derived = try GasFreeAddressResolver.resolveLocally(userAddress: userAddress)

        #expect(derived.base58 == vector.expectedGasFreeAddress)
    }
}
