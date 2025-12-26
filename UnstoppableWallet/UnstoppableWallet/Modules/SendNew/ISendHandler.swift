import MarketKit

protocol ISendHandler {
    var baseToken: Token { get }
    var syncingText: String? { get }
    var expirationDuration: Int? { get }
    var initialTransactionSettings: InitialTransactionSettings? { get }
    var menuItems: [SendMenuItem] { get }
    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData
    func send(data: ISendData) async throws
}

extension ISendHandler {
    var syncingText: String? { nil }
    var expirationDuration: Int? { nil }
    var initialTransactionSettings: InitialTransactionSettings? { nil }
    var menuItems: [SendMenuItem] { [] }
}

struct SendMenuItem {
    let label: String
    let action: () -> Void
}
