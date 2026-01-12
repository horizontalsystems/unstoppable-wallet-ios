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
        var fee: Decimal?
        var transactionError: Error?

        if let priority {
            do {
                fee = try adapter.estimateFee(amount: amount, address: address, priority: priority)
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
            fee: fee
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
        let fee: Decimal?

        init(token: Token, amount: MoneroSendAmount, address: String, priority: SendPriority, memo: String?, transactionError: Error?, fee: Decimal?) {
            self.token = token
            self.amount = amount
            self.address = address
            self.priority = priority
            self.memo = memo
            self.transactionError = transactionError
            self.fee = fee
        }

        var feeData: FeeData? {
            .monero(amount: amount, address: address)
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

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            guard let transactionError else {
                return []
            }

            return [MoneroSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
        }

        func feeData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
            guard let fee else {
                return nil
            }

            return AmountData(
                appValue: AppValue(token: feeToken, value: fee),
                currencyValue: feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }
            )
        }

        func amountData(amountToken: Token, currency: Currency, amountTokenRate: Decimal?) -> AmountData {
            let value: Decimal
            switch amount {
            case let .all(_value):
                if let fee {
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

        func sections(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            let rate = rates[token.coin.uid]
            let amountData = amountData(amountToken: token, currency: currency, amountTokenRate: rate)

            var sections = [SendDataSection]()
            sections.append(.init([
                .amountNew(
                    token: token,
                    appValueType: .regular(appValue: amountData.appValue),
                    currencyValue: amountData.currencyValue,
                ),
                .address(
                    value: address,
                    blockchainType: .monero
                ),
            ], isFlow: true))

            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            sections.append(
                .init(fields + MoneroSendHelper.feeFields(fee: fee, feeToken: token, currency: currency, feeTokenRate: rate, priority: priority), isMain: false)
            )

            return sections
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
