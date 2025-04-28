import Foundation
import MarketKit
import StellarKit

class StellarOperationConverter {
    private let accountId: String
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: CoinManager

    init(accountId: String, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.accountId = accountId
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
    }

    private func assetValue(asset: Asset, value: Decimal) -> AppValue {
        let tokenType: TokenType

        switch asset {
        case .native: tokenType = .native
        case let .asset(code, issuer): tokenType = .stellar(code: code, issuer: issuer)
        }

        let query = TokenQuery(blockchainType: .stellar, tokenType: tokenType)

        if let token = try? coinManager.token(query: query) {
            return AppValue(token: token, value: value)
        } else {
            return AppValue(asset: asset, value: value)
        }
    }

    private func type(type: TxOperation.`Type`) -> StellarTransactionRecord.`Type` {
        switch type {
        case let .accountCreated(data):
            if data.account == accountId {
                return .accountCreated(startingBalance: AppValue(token: baseToken, value: data.startingBalance), funder: data.funder)
            } else {
                return .unsupported(type: "accountCreated") // todo
            }
        case let .payment(data):
            if data.from == accountId {
                return .sendPayment(value: assetValue(asset: data.asset, value: -data.amount), to: data.to, sentToSelf: data.to == accountId)
            } else {
                return .receivePayment(value: assetValue(asset: data.asset, value: data.amount), from: data.from)
            }
        case let .unknown(rawType):
            return .unsupported(type: rawType)
        }
    }
}

extension StellarOperationConverter {
    func transactionRecord(operation: TxOperation) -> StellarTransactionRecord {
        StellarTransactionRecord(source: source, operation: operation, baseToken: baseToken, type: type(type: operation.type))
    }
}
