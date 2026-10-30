import Alamofire
import Foundation
import NearKit
import Testing
@testable import WalletCore
import XrpKit

/// NearKit and XrpKit throw NoEndpointAvailable over the last transport error once every node has
/// failed; a lost connection under it reads as "no internet", anything else stays the kit's error.
struct NoEndpointAvailableConvertedErrorTests {
    @Test func nearLostConnectionIsNoConnection() {
        let error = NearKit.NoEndpointAvailable(underlying: URLError(.notConnectedToInternet))

        guard case .noConnection? = error.convertedError as? AppError else {
            Issue.record("expected no connection, got \(error.convertedError)")
            return
        }
    }

    @Test func xrpLostConnectionWrappedByAlamofireIsNoConnection() {
        let error = XrpKit.NoEndpointAvailable(underlying: AFError.sessionTaskFailed(error: URLError(.networkConnectionLost)))

        guard case .noConnection? = error.convertedError as? AppError else {
            Issue.record("expected no connection, got \(error.convertedError)")
            return
        }
    }

    @Test func otherFailuresKeepTheKitsError() {
        #expect(NearKit.NoEndpointAvailable(underlying: nil).convertedError is NearKit.NoEndpointAvailable)
        #expect(XrpKit.NoEndpointAvailable(underlying: URLError(.badServerResponse)).convertedError is XrpKit.NoEndpointAvailable)
    }
}
