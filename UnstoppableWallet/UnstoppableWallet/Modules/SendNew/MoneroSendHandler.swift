import Foundation
import MarketKit
import MoneroKit

class MoneroSendHandler {
    private let token: Token
    private let adapter: MoneroAdapter
    private let amount: MoneroSendAmount
    private let address: String
    private let memo: String?

    init(token: Token, adapter: MoneroAdapter, amount: MoneroSendAmount, address: String, memo: String?) {
        self.token = token
        self.adapter = adapter
        self.amount = amount
        self.address = address
        self.memo = memo
    }
}

extension MoneroSendHandler: ISendHandler {
    var baseToken: MarketKit.Token {
        token
    }

    var expirationDuration: Int? {
        60
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let priority = transactionSettings?.priority
        var feeData: BitcoinFeeData?
        var transactionError: Error?

        if let priority {
            do {
                let fee = try adapter.estimateFee(amount: amount, address: address, priority: priority)
                feeData = .init(fee: fee)
            } catch {
                transactionError = error
            }
        }

        return SendData(
            token: token,
            amount: amount,
            address: address,
            priority: priority ?? .default,
            memo: memo,
            transactionError: transactionError,
            fee: feeData
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        try adapter.send(to: data.address, amount: data.amount, priority: data.priority, memo: data.memo)
    }
}

extension MoneroSendHandler {
    class SendData: ISendData {
        let token: Token
        let amount: MoneroSendAmount
        let address: String
        let priority: SendPriority
        let memo: String?
        let transactionError: Error?
        let fee: BitcoinFeeData?

        init(token: Token, amount: MoneroSendAmount, address: String, priority: SendPriority, memo: String?, transactionError: Error?, fee: BitcoinFeeData?) {
            self.token = token
            self.amount = amount
            self.address = address
            self.priority = priority
            self.memo = memo
            self.transactionError = transactionError
            self.fee = fee
        }

        var feeData: FeeData? {
            fee.map { .bitcoin(bitcoinFeeData: $0) }
        }

        var canSend: Bool {
            transactionError == nil
        }

        var customSendButtonTitle: String? {
            nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let moneroError = transactionError as? MoneroCoreError {
                switch moneroError {
                case let .insufficientFunds(balance):
                    let appValue = AppValue(token: feeToken, value: Decimal(string: balance) ?? 0)
                    let balanceString = appValue.formattedShort()

                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
                default:
                    title = "ethereum_transaction.error.title".localized
                    text = transactionError.convertedError.smartDescription
                }
            } else {
                title = "ethereum_transaction.error.title".localized
                text = transactionError.convertedError.smartDescription
            }

            return CautionNew(title: title, text: text, type: .error)
        }

        func cautions(baseToken: Token) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func feeData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
            guard let fee else {
                return nil
            }

            return AmountData(
                appValue: AppValue(token: feeToken, value: fee.fee),
                currencyValue: feeTokenRate.map { CurrencyValue(currency: currency, value: fee.fee * $0) }
            )
        }

        func amountData(amountToken: Token, currency: Currency, amountTokenRate: Decimal?) -> AmountData {
            let value: Decimal
            switch amount {
            case let .all(_value):
                if let fee = fee?.fee {
                    value = _value - fee
                } else {
                    value = _value
                }
            case let .value(_value):
                value = _value
            }

            return AmountData(
                appValue: AppValue(token: amountToken, value: value),
                currencyValue: amountTokenRate.map { CurrencyValue(currency: currency, value: value * $0) }
            )
        }

        func feeFields(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
            let feeData = feeData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

            return [
                .value(
                    title: "fee_settings.network_fee".localized,
                    description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                    appValue: feeData?.appValue,
                    currencyValue: feeData?.currencyValue,
                    formatFull: true
                ),
            ]
        }

        func sections(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = [SendField]()
            let rate = rates[token.coin.uid]
            let amountData = amountData(amountToken: token, currency: currency, amountTokenRate: rate)

            fields.append(contentsOf: [
                .amount(
                    title: "send.confirmation.you_send".localized,
                    token: token,
                    appValueType: .regular(appValue: amountData.appValue),
                    currencyValue: amountData.currencyValue,
                    type: .neutral
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: address,
                    blockchainType: .monero
                ),
                .levelValue(
                    title: "monero.priority".localized,
                    value: priority.description,
                    level: priority.level
                ),
            ])

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            return [.init(fields), .init(feeFields(feeToken: token, currency: currency, feeTokenRate: rate))]
        }
    }
}

extension MoneroSendHandler {
    enum SendError: Error {
        case invalidFee
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientMoneroBalance(balance: Decimal)
        case noTrustline
    }
}

extension MoneroSendHandler {
    static func instance(token: Token, amount: MoneroSendAmount, address: String, memo: String?) -> MoneroSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? MoneroAdapter else {
            return nil
        }

        return MoneroSendHandler(
            token: token,
            adapter: adapter,
            amount: amount,
            address: address,
            memo: memo
        )
    }
}
