import Foundation
import MarketKit
import stellarsdk

class WCNStellarData {
    let xdr: String
    let transaction: stellarsdk.Transaction
    let sourceAccountId: String

    init(xdr: String, transaction: stellarsdk.Transaction, sourceAccountId: String) {
        self.xdr = xdr
        self.transaction = transaction
        self.sourceAccountId = sourceAccountId
    }

    var baseSections: [SendDataSection] {
        var transactionFields = transaction.operations.map {
            SendField.simpleValue(title: "send.confirmation.operation".localized, value: String(describing: type(of: $0)))
        }
        transactionFields.append(.simpleValue(title: "send.confirmation.transaction_xdr".localized, value: xdr.shortened))

        let accountFields = [SendField.simpleValue(title: WCNNamespace.stellar.capitalized, value: sourceAccountId.shortened)]

        return [SendDataSection(transactionFields), SendDataSection(accountFields, isMain: false)]
    }
}

class WCNStellarSignData: WCNStellarData, ISendData {
    var feeData: FeeData? { nil }
    var canSend: Bool { true }
    var rateCoins: [Coin] { [] }

    func cautions(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        []
    }

    func sections(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
        baseSections
    }
}

class WCNStellarSubmitData: WCNStellarData, ISendData {
    private let token: Token
    private let fee: Decimal?
    private let transactionError: Error?

    init(token: Token, xdr: String, transaction: stellarsdk.Transaction, sourceAccountId: String, fee: Decimal?, transactionError: Error?) {
        self.token = token
        self.fee = fee
        self.transactionError = transactionError
        super.init(xdr: xdr, transaction: transaction, sourceAccountId: sourceAccountId)
    }

    var feeData: FeeData? { nil }
    var canSend: Bool { transactionError == nil }
    var rateCoins: [Coin] { [token.coin] }

    func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
        guard let transactionError else {
            return []
        }

        if case let WCNStellarSendHandler.TransactionError.insufficientBalance(balance) = transactionError {
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
        var sections = baseSections

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
