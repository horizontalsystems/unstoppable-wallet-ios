import Combine
import Foundation

// Both request sheets observe the kit's existing deadline/SDK/foreground updates.
class WCRequestExpirationViewModel: ObservableObject {
    @Published private(set) var isExpired: Bool

    private var cancellable: AnyCancellable?

    init(request: WCRequest?, updates: AnyPublisher<Void, Never>? = Core.shared.walletConnect?.startedKit?.pendingRequestsPublisher) {
        isExpired = request?.isExpired ?? false
        cancellable = updates?
            .prepend(())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                let expired = request?.isExpired ?? false
                if isExpired != expired {
                    isExpired = expired
                }
            }
    }
}
