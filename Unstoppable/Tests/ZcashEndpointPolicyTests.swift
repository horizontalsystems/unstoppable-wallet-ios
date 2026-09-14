import Foundation
import Testing
@testable import WalletCore
import ZcashLightClientKit

struct ZcashEndpointPolicyTests {
    private let a = LightWalletEndpoint(address: "a", port: 443)
    private let b = LightWalletEndpoint(address: "b", port: 443)

    @Test func successMovesToTarget() {
        #expect(ZcashEndpointService.endpointAfterRebuild(target: b, current: a, error: nil) == b)
    }

    @Test func anyErrorKeepsCurrent() {
        struct Boom: Error {}
        #expect(ZcashEndpointService.endpointAfterRebuild(target: b, current: a, error: Boom()) == a)
        #expect(ZcashEndpointService.endpointAfterRebuild(target: b, current: a, error: ZcashError.slipstreamEngineNotQuiescent) == a)
    }

    @Test func quiescenceRefusalIsRecognised() {
        #expect(ZcashEndpointService.isQuiescenceRefusal(ZcashError.slipstreamEngineNotQuiescent))
        #expect(!ZcashEndpointService.isQuiescenceRefusal(ZcashError.synchronizerNotPrepared))
    }
}
