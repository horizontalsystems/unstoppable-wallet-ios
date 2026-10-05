import Foundation
import MarketKit

class WCSolanaSendData: ISendData {
    private let token: Token
    private let payload: WCSolanaTransactionPayload
    private let fee: Decimal?
    private let transactionError: Error?
    private let summaries: [WCSolanaTransactionSummary]

    init(token: Token, payload: WCSolanaTransactionPayload, fee: Decimal?, transactionError: Error?) {
        self.token = token
        self.payload = payload
        self.fee = fee
        self.transactionError = transactionError
        summaries = payload.rawTransactions.map { WCSolanaTransactionSummary(rawTransaction: $0) }
    }

    var feeData: FeeData? { nil }
    var canSend: Bool { transactionError == nil }
    var rateCoins: [Coin] { [token.coin] }

    func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        var cautions = [CautionNew]()

        // Display all distinct warnings in severity order; their color does not change canSend.
        let warnings = summaries.reduce(into: Set<WCSolanaTransactionSummary.Warning>()) { $0.formUnion($1.warnings) }
        for warning in WCSolanaTransactionSummary.Warning.allCases where warnings.contains(warning) {
            switch warning {
            case .hiddenRecipient:
                cautions.append(CautionNew(title: "wallet_connect.solana.hidden_recipient.title".localized, text: "wallet_connect.solana.hidden_recipient.text".localized, type: .error))
            case .unreadable:
                cautions.append(CautionNew(title: "wallet_connect.solana.unreadable_transaction.title".localized, text: "wallet_connect.solana.unreadable_transaction.text".localized, type: .warning))
            case .unknownInstructions:
                cautions.append(CautionNew(title: "wallet_connect.solana.unknown_instructions.title".localized, text: "wallet_connect.solana.unknown_instructions.text".localized, type: .warning))
            }
        }

        if let transactionError {
            if case let WCSolanaSendHandler.TransactionError.insufficientBalance(balance) = transactionError {
                let balanceString = AppValue(token: baseToken, value: balance).formattedShort() ?? ""
                cautions.append(CautionNew(
                    title: "fee_settings.errors.insufficient_balance".localized,
                    text: "fee_settings.errors.insufficient_balance.info".localized(balanceString),
                    type: .error
                ))
            } else {
                cautions.append(CautionNew(title: "ethereum_transaction.error.title".localized, text: transactionError.convertedError.smartDescription, type: .error))
            }
        }

        return cautions
    }

    func sections(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
        var fields = [SendField]()

        if payload.rawTransactions.count > 1 {
            fields.append(.simpleValue(title: "wallet_connect.request.transactions".localized, value: String(payload.rawTransactions.count)))
        }
        for summary in summaries {
            fields.append(contentsOf: summary.fields(baseToken: baseToken, signer: payload.from))
        }

        return [SendDataSection(fields)]
    }

    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        guard let fee else {
            return []
        }
        // the network fee is paid by the transaction's fee payer (accountKeys[0]); a dApp can set a
        // different fee payer (sponsored tx), so only show the fee when this wallet actually pays it
        guard let signer = payload.from, summaries.allSatisfy({ $0.feePayer == signer }) else {
            return []
        }
        return [
            .value(
                title: ComponentInformedTitle("send.confirmation.fee".localized, info: .fee),
                appValue: AppValue(token: baseToken, value: fee),
                currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) },
                formatFull: true
            ),
        ]
    }
}
