import Foundation
import MarketKit

class ZanoSendHandler {
    private let token: Token
    private let adapter: ZanoAdapter
    private let amount: ZanoSendAmount
    private let address: String
    private let memo: String?

    init(token: Token, adapter: ZanoAdapter, amount: ZanoSendAmount, address: String, memo: String?) {
        self.token = token
        self.adapter = adapter
        self.amount = amount
        self.address = address
        self.memo = memo
    }
}

extension ZanoSendHandler: ISendHandler {
    var baseToken: MarketKit.Token {
        token
    }

    var expirationDuration: Int? {
        60
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let fee = adapter.estimateFee()

        return SendData(
            token: token,
            amount: amount,
            address: address,
            memo: memo,
            transactionError: nil,
            fee: fee
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        try adapter.send(to: data.address, amount: data.amount, memo: data.memo)
    }
}

extension ZanoSendHandler {
    class SendData: ISendData {
        let token: Token
        let amount: ZanoSendAmount
        let address: String
        let memo: String?
        let transactionError: Error?
        let fee: Decimal?

        init(token: Token, amount: ZanoSendAmount, address: String, memo: String?, transactionError: Error?, fee: Decimal?) {
            self.token = token
            self.amount = amount
            self.address = address
            self.memo = memo
            self.transactionError = transactionError
            self.fee = fee
        }

        var feeData: FeeData? {
            nil
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

            return [ZanoSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
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
                .amount(
                    token: token,
                    appValueType: .regular(appValue: amountData.appValue),
                    currencyValue: amountData.currencyValue
                ),
                .address(
                    value: address,
                    blockchainType: .zano
                ),
            ], isFlow: true))

            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            sections.append(
                .init(fields + ZanoSendHelper.feeFields(fee: fee, feeToken: token, currency: currency, feeTokenRate: rate), isMain: false)
            )

            return sections
        }
    }
}

extension ZanoSendHandler {
    enum SendError: Error {
        case invalidFee
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientZanoBalance(balance: Decimal)
    }
}

extension ZanoSendHandler {
    static func instance(token: Token, amount: ZanoSendAmount, address: String, memo: String?) -> ZanoSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZanoAdapter else {
            return nil
        }

        return ZanoSendHandler(
            token: token,
            adapter: adapter,
            amount: amount,
            address: address,
            memo: memo
        )
    }
}
