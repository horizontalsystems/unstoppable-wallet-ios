import Foundation
import MarketKit
import MoneroKit

class MoneroSendHandler {
    private let token: Token
    private let adapter: MoneroAdapter
    private let amount: Decimal
    private let address: String

    init(token: Token, adapter: MoneroAdapter, amount: Decimal, address: String) {
        self.token = token
        self.adapter = adapter
        self.amount = amount
        self.address = address
    }
}

extension MoneroSendHandler: ISendHandler {
    var baseToken: MarketKit.Token {
        token
    }

    var expirationDuration: Int? {
        10
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
            transactionError: transactionError,
            fee: feeData
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        try adapter.send(to: data.address, amount: data.amount, priority: data.priority)
    }
}

extension MoneroSendHandler {
    class SendData: ISendData {
        let token: Token
        let amount: Decimal
        let address: String
        let priority: SendPriority
        let transactionError: Error?
        let fee: BitcoinFeeData?

        init(token: Token, amount: Decimal, address: String, priority: SendPriority, transactionError: Error?, fee: BitcoinFeeData?) {
            self.token = token
            self.amount = amount
            self.address = address
            self.priority = priority
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

            if let moneroError = transactionError as? MoneroSendHandler.TransactionError {
                switch moneroError {
                case let .insufficientMoneroBalance(balance):
                    let appValue = AppValue(token: feeToken, value: balance)
                    let balanceString = appValue.formattedShort()

                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
                case .noTrustline:
                    title = "send.monero.no_trustline.title".localized
                    text = "send.monero.no_trustline.description".localized
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

        func amountData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
            guard let fee else {
                return nil
            }

            return AmountData(
                appValue: AppValue(token: feeToken, value: fee.fee),
                currencyValue: feeTokenRate.map { CurrencyValue(currency: currency, value: fee.fee * $0) }
            )
        }

        func feeFields(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
            let amountData = amountData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

            return [
                .value(
                    title: "fee_settings.network_fee".localized,
                    description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                    appValue: amountData?.appValue,
                    currencyValue: amountData?.currencyValue,
                    formatFull: true
                ),
            ]
        }

        func sections(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = [SendField]()
            let rate = rates[token.coin.uid]

            fields.append(contentsOf: [
                .amount(
                    title: "send.confirmation.you_send".localized,
                    token: token,
                    appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                    currencyValue: rate.map { CurrencyValue(currency: currency, value: $0 * amount) },
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
    static func instance(token: Token, amount: Decimal, address: String) -> MoneroSendHandler? {
        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? MoneroAdapter else {
            return nil
        }

        return MoneroSendHandler(
            token: token,
            adapter: adapter,
            amount: amount,
            address: address
        )
    }
}
