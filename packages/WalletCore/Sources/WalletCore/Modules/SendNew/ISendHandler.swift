import Combine
import MarketKit

public protocol ISendHandler {
    var baseToken: Token { get }
    var syncingText: String? { get }
    var expirationDuration: Int? { get }
    // When false, a quote that reaches its `expirationDuration` is not silently re-requested;
    // instead the screen marks it expired and waits for the user to refresh manually. Swaps
    // opt out of auto-refresh so we don't keep hitting the provider's commit endpoint.
    var autoRefreshEnabled: Bool { get }
    var initialTransactionSettings: InitialTransactionSettings? { get }
    var menuItems: [SendMenuItem] { get }
    var refreshPublisher: AnyPublisher<Void, Never>? { get }
    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData
    func send(data: ISendData) async throws
}

public extension ISendHandler {
    var syncingText: String? { nil }
    var expirationDuration: Int? { nil }
    var autoRefreshEnabled: Bool { true }
    var initialTransactionSettings: InitialTransactionSettings? { nil }
    var menuItems: [SendMenuItem] { [] }
    var refreshPublisher: AnyPublisher<Void, Never>? { nil }
}

public struct SendMenuItem {
    public let label: String
    public let action: () -> Void

    public init(label: String, action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
}
