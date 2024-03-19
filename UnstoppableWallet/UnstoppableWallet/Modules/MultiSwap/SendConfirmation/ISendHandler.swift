import MarketKit

protocol ISendHandler {
    var blockchainType: BlockchainType { get }
    func confirmationData(transactionSettings: TransactionSettings?) async throws -> ISendConfirmationData
    func send(data: ISendConfirmationData) async throws
}
