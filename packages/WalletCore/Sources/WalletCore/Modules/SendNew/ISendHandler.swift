import Combine
import MarketKit

public protocol ISendHandler {
    var baseToken: Token { get }
    var syncingText: String? { get }
    var expirationDuration: Int? { get }
    var initialTransactionSettings: InitialTransactionSettings? { get }
    var menuItems: [SendMenuItem] { get }
    var refreshPublisher: AnyPublisher<Void, Never>? { get }
    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData
    func send(data: ISendData) async throws
}

extension ISendHandler {
    public var syncingText: String? { nil }
    public var expirationDuration: Int? { nil }
    public var initialTransactionSettings: InitialTransactionSettings? { nil }
    public var menuItems: [SendMenuItem] { [] }
    public var refreshPublisher: AnyPublisher<Void, Never>? { nil }
}

public struct SendMenuItem {
    let label: String
    let action: () -> Void
}
