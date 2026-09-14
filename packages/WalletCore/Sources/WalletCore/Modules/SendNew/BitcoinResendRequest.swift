import MarketKit

public struct BitcoinResendRequest {
    let token: Token
    let transaction: BitcoinOutgoingTransactionRecord
    let type: ResendTransactionType
}
