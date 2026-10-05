import Foundation
import MarketKit
import XrpKit

class XrpTransactionConverter {
    private let selfAddress: String
    private let source: TransactionSource
    private let baseToken: Token
    private let coinManager: CoinManager

    init(selfAddress: String, source: TransactionSource, baseToken: Token, coinManager: CoinManager) {
        self.selfAddress = selfAddress
        self.source = source
        self.baseToken = baseToken
        self.coinManager = coinManager
    }

    func transactionRecord(transaction: XrpKit.Transaction) -> XrpTransactionRecord {
        let type: XrpTransactionRecord.`Type`
        switch transaction.type {
        case "Payment": type = paymentType(transaction: transaction)
        case "TrustSet": type = trustSetType(transaction: transaction)
        default: type = .unsupported(type: transaction.type)
        }

        return XrpTransactionRecord(source: source, transaction: transaction, baseToken: baseToken, type: type, spam: false)
    }

    private func paymentType(transaction: XrpKit.Transaction) -> XrpTransactionRecord.`Type` {
        let outgoing = transaction.account == selfAddress
        let incoming = transaction.destination == selfAddress
        guard let amount = Self.shownPaymentAmount(transaction: transaction) else {
            return .unsupported(type: transaction.type)
        }

        if outgoing {
            return .send(value: appValue(amount: amount, negate: true), to: transaction.destination ?? "", sentToSelf: incoming)
        }
        if incoming {
            return .receive(value: appValue(amount: amount, negate: false), from: transaction.account)
        }
        return .unsupported(type: transaction.type)
    }

    // What the destination actually received. A successful payment without it is a partial payment
    // whose delivered amount the ledger no longer reports; its Amount is only an upper bound, so it must
    // not be shown as received. Pending and failed payments delivered nothing and show the amount sent
    // (as on Android)
    static func shownPaymentAmount(transaction: XrpKit.Transaction) -> Amount? {
        if let deliveredAmount = transaction.deliveredAmount {
            return deliveredAmount
        }

        return transaction.isSuccess ? nil : transaction.amount
    }

    private func trustSetType(transaction: XrpKit.Transaction) -> XrpTransactionRecord.`Type` {
        guard let limit = transaction.limitAmount, let issuer = limit.issuer else {
            return .unsupported(type: transaction.type)
        }
        return .trustSet(value: appValue(amount: limit, negate: false), issuer: issuer)
    }

    private func appValue(amount: Amount, negate: Bool) -> AppValue {
        let value = negate ? -amount.decimalValue : amount.decimalValue

        switch amount {
        case .xrp:
            return AppValue(token: baseToken, value: value)
        case let .issued(_, currency, issuer):
            let query = TokenQuery(blockchainType: .xrp, tokenType: .xrpAsset(currency: currency, issuer: issuer))
            if let token = try? coinManager.token(query: query) {
                return AppValue(token: token, value: value)
            }
            let code = XrpKit.Kit.displayCurrencyCode(currency)
            return AppValue(kind: .eip20Token(tokenName: code, tokenCode: code, tokenDecimals: XrpKitManager.issuedTokenDecimals), value: value)
        }
    }
}
