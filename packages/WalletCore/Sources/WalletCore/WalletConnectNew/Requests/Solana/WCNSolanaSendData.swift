import Foundation
import MarketKit

class WCNSolanaSendData: ISendData {
    private let token: Token
    private let parsed: WCNSolanaTransactionParsed
    private let fee: Decimal?
    private let transactionError: Error?

    init(token: Token, parsed: WCNSolanaTransactionParsed, fee: Decimal?, transactionError: Error?) {
        self.token = token
        self.parsed = parsed
        self.fee = fee
        self.transactionError = transactionError
    }

    var feeData: FeeData? { nil }
    var canSend: Bool { transactionError == nil }
    var rateCoins: [Coin] { [token.coin] }

    func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        guard let transactionError else {
            return []
        }

        if case let WCNSolanaSendHandler.TransactionError.insufficientBalance(balance) = transactionError {
            let balanceString = AppValue(token: baseToken, value: balance).formattedShort() ?? ""
            return [CautionNew(
                title: "fee_settings.errors.insufficient_balance".localized,
                text: "fee_settings.errors.insufficient_balance.info".localized(balanceString),
                type: .error
            )]
        }

        return [CautionNew(title: "ethereum_transaction.error.title".localized, text: transactionError.convertedError.smartDescription, type: .error)]
    }

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        var transactionFields = [SendField]()

        if parsed.rawTransactions.count > 1 {
            transactionFields.append(.simpleValue(title: "wallet_connect.request.transactions".localized, value: String(parsed.rawTransactions.count)))
        }
        for signer in Set(parsed.requiredSigners.flatMap { $0 }).sorted() {
            transactionFields.append(.simpleValue(title: "wallet_connect.request.signer".localized, value: signer.shortened))
        }

        var sections = [SendDataSection(transactionFields)]

        if let from = parsed.from {
            sections.append(SendDataSection([.simpleValue(title: WCNNamespace.solana.capitalized, value: from.shortened)], isMain: false))
        }

        if let fee {
            let infoDescription = InfoDescription(title: "send.max_fee".localized, description: "fee_settings.network_fee.info".localized)
            sections.append(SendDataSection([
                .value(
                    title: ComponentInformedTitle("send.max_fee".localized, info: infoDescription),
                    appValue: AppValue(token: baseToken, value: fee),
                    currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) },
                    formatFull: true
                ),
            ], isMain: false))
        }

        return sections
    }
}
