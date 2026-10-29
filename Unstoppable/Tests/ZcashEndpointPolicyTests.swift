import Foundation
import Testing
@testable import WalletCore
import ZODLSwiftWalletSDK

struct ZcashEndpointPolicyTests {
    private let a = LightWalletEndpoint(address: "a", port: 443)
    private let b = LightWalletEndpoint(address: "b", port: 443)

    @Test func successMovesToTarget() {
        #expect(ZcashEndpointService.endpointAfterRebuild(target: b, current: a, error: nil) == b)
    }

    @Test func anyErrorKeepsCurrent() {
        struct Boom: Error {}
        #expect(ZcashEndpointService.endpointAfterRebuild(target: b, current: a, error: Boom()) == a)
        let report = SlipstreamStopReport(settled: false, drained: false, settleWait: .seconds(10), drainWait: .seconds(10))
        #expect(ZcashEndpointService.endpointAfterRebuild(target: b, current: a, error: ZcashError.slipstreamEngineNotQuiescent(report)) == a)
    }
}
