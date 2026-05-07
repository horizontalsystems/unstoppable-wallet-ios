import HsExtensions
import Testing
import TronKit
@testable import Unstoppable

struct PermitTransferHashTests {
    @Test func mainnetHashMatchesUpstreamSDK() throws {
        let v = GasFreeFixtures.PermitTransferHash.mainnetExample

        let domain = try GasFreeDomain(
            name: "GasFreeController",
            version: "V1.0.0",
            chainId: v.chainId,
            verifyingContract: TronKit.Address(address: v.verifyingContract)
        )
        let message = try PermitTransfer.Message(
            token: TronKit.Address(address: v.token),
            serviceProvider: TronKit.Address(address: v.serviceProvider),
            user: TronKit.Address(address: v.user),
            receiver: TronKit.Address(address: v.receiver),
            value: v.value,
            maxFee: v.maxFee,
            deadline: v.deadline,
            version: v.version,
            nonce: v.nonce
        )

        let hash = PermitTransfer.hash(domain: domain, message: message)

        #expect(hash.hs.hex == v.expectedHashHex)
    }
}
