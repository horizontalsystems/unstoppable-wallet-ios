import Combine
import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCRequestExpirationViewModelTests {
    @Test(arguments: [UInt64(0), UInt64.max, nil])
    func initialStateUsesRequestDeadline(timestamp: UInt64?) throws {
        var raw = try WCTestFixtures.request()
        raw.expiryTimestamp = timestamp
        let request = WCRequest(payload: WCRequestPayload(request: raw, kind: .signMessage, from: nil), verdict: .pass, dAppName: "dApp")

        let viewModel = WCRequestExpirationViewModel(request: request, updates: nil)

        #expect(viewModel.isExpired == (timestamp == 0))
    }

    @Test func subscriptionDoesNotRetainViewModel() {
        let updates = PassthroughSubject<Void, Never>()
        weak var released: WCRequestExpirationViewModel?
        do {
            let viewModel = WCRequestExpirationViewModel(request: nil, updates: updates.eraseToAnyPublisher())
            released = viewModel
            #expect(released != nil)
        }
        #expect(released == nil)
    }
}
