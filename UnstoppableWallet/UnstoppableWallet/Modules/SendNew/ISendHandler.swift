import MarketKit

protocol ISendHandler {
    var blockchainType: BlockchainType { get }
    var syncingText: String? { get }
    var expirationDuration: Int { get }
    func confirmationData(transactionSettings: TransactionSettings?) async throws -> ISendConfirmationData
    func send(data: ISendConfirmationData) async throws
}
