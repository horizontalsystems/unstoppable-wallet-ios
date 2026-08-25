import Combine
import Foundation
import MarketKit

// Deliberately tiny: it does no quoting, holds no tasks and has nothing to cancel. All network work
// lives in PrivateSendHandler, on the confirmation screen.
@MainActor
public final class PrivateSendViewModel: ObservableObject {
    private let token: Token
    private let service: PrivateSendService?
    private var cancellables = Set<AnyCancellable>()

    // A synchronous read of the already-background-synced confidential token cache: it never blocks
    // and never triggers a fetch on the render path.
    @Published public private(set) var isSupported: Bool

    @Published public var isEnabled: Bool = false

    public init(token: Token, service: PrivateSendService?) {
        self.token = token
        self.service = service

        // A nil service yields isSupported == false permanently, so an app that never wires private
        // send is unaffected.
        isSupported = service?.isSupported(token: token) ?? false

        service?.syncPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.syncSupported() }
            .store(in: &cancellables)
    }

    public func request(recipient: String, amount: Decimal) -> PrivateSendRequest {
        PrivateSendRequest(token: token, recipient: recipient, amount: amount)
    }

    private func syncSupported() {
        let isSupported = service?.isSupported(token: token) ?? false

        guard isSupported != self.isSupported else {
            return
        }

        self.isSupported = isSupported

        // Never leave a private-send UI enabled for a token that can no longer route.
        if !isSupported {
            isEnabled = false
        }
    }
}
