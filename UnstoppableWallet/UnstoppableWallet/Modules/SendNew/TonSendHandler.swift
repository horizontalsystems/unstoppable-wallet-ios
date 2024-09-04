import BigInt
import Foundation
import MarketKit
import TonKit

class TonSendHandler {
    private let token: Token
    private let adapter: ISendTonAdapter
    private var amount: Decimal
    private let address: String
    private let memo: String?

    init(token: Token, adapter: ISendTonAdapter, amount: Decimal, address: String, memo: String?) {
        self.token = token
        self.adapter = adapter
        self.amount = amount
        self.address = address
        self.memo = memo
    }
}

extension TonSendHandler {
    class SendData: ISendData {
        private let token: Token
        private let amount: Decimal
        private let address: String
        private let memo: String?
        let fee: Decimal?
        private let transactionError: Error?
        var feeData: FeeData? = nil

        init(token: Token, amount: Decimal, address: String, memo: String?, fee: Decimal?, transactionError: Error?) {
            self.token = token
            self.amount = amount
            self.address = address
            self.memo = memo
            self.fee = fee
            self.transactionError = transactionError
        }

        var canSend: Bool {
            fee != nil && transactionError == nil
        }

        var customSendButtonTitle: String? {
            nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let tonError = transactionError as? TonSendHandler.TransactionError {
                switch tonError {
                case let .insufficientBalance(balance):
                    let coinValue = CoinValue(kind: .token(token: feeToken), value: balance)
                    let balanceString = ValueFormatter.instance.formatShort(coinValue: coinValue)

                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")

                case .zeroAmount:
                    title = "alert.error".localized
                    text = "fee_settings.errors.zero_amount.info".localized
                }
            } else {
                title = "Error"
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

        func sections(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            var fields: [SendField] = [
                .amount(
                    title: "send.confirmation.you_send".localized,
                    token: token,
                    coinValueType: .regular(coinValue: CoinValue(kind: .token(token: token), value: amount)),
                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) },
                    type: .neutral
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: address,
                    blockchainType: .ton
                ),
            ]

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            return [
                fields,
                feeFields(currency: currency, feeTokenRate: rates[token.coin.uid]),
            ]
        }

        private func feeFields(currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
            var viewItems = [SendField]()

            if let fee {
                let coinValue = CoinValue(kind: .token(token: token), value: fee)
                let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

                viewItems.append(
                    .value(
                        title: "fee_settings.network_fee".localized,
                        description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                        coinValue: coinValue,
                        currencyValue: currencyValue,
                        formatFull: true
                    )
                )
            }

            return viewItems
        }
    }
}

extension TonSendHandler: ISendHandler {
    var baseToken: Token {
        token
    }

    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        var fee: Decimal?
        var transactionError: Error?
        let tonBalance = adapter.availableBalance

        do {
            let _fee = try await adapter.estimateFee(recipient: address, amount: amount, comment: memo)
            var totalAmount = Decimal.zero

            var sentAmount = amount
            if tonBalance == amount {
                // If the maximum amount is being sent, then we subtract fees from sent amount
                sentAmount = sentAmount - _fee

                guard sentAmount > 0 else {
                    throw TransactionError.zeroAmount
                }

                amount = sentAmount
            }

            totalAmount += sentAmount
            totalAmount += _fee
            fee = _fee

            if tonBalance < totalAmount {
                throw TransactionError.insufficientBalance(balance: tonBalance)
            }
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            amount: amount,
            address: address,
            memo: memo,
            fee: fee,
            transactionError: transactionError
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        guard data.fee != nil else {
            throw SendError.noFees
        }

        _ = try await adapter.send(
            recipient: address,
            amount: amount,
            comment: memo
        )
    }
}

extension TonSendHandler {
    enum SendError: Error {
        case invalidData
        case noFees
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
        case zeroAmount
    }
}

extension TonSendHandler {
    static func instance(amount: Decimal, address: String, memo: String?) -> TonSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: .ton, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: baseToken) as? ISendTonAdapter else {
            return nil
        }

        return TonSendHandler(
            token: baseToken,
            adapter: adapter,
            amount: amount,
            address: address,
            memo: memo
        )
    }
}
