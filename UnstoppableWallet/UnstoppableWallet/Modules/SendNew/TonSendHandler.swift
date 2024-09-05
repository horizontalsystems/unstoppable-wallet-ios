import BigInt
import Foundation
import MarketKit
import TonKit
import TonSwift

class TonSendHandler {
    private let tonKit: TonKit.Kit
    private let token: Token
    let baseToken: Token
    private let adapter: ISendTonAdapter & IBalanceAdapter
    private let amount: Decimal
    private let address: FriendlyAddress
    private let memo: String?

    init(tonKit: TonKit.Kit, token: Token, baseToken: Token, adapter: ISendTonAdapter & IBalanceAdapter, amount: Decimal, address: FriendlyAddress, memo: String?) {
        self.tonKit = tonKit
        self.token = token
        self.baseToken = baseToken
        self.adapter = adapter
        self.amount = amount
        self.address = address
        self.memo = memo
    }
}

extension TonSendHandler: ISendHandler {
    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        var fee: Decimal?
        var transactionError: Error?
        let tonBalance = TonAdapter.amount(kitAmount: tonKit.account?.balance)

        var sendAmount: TonAdapter.SendAmount = .amount(value: amount)

        if token.type.isNative, amount == tonBalance {
            sendAmount = .max
        }

        var finalAmount = amount

        do {
            let estimatedFee = try await adapter.estimateFee(recipient: address, amount: sendAmount, comment: memo)
            fee = estimatedFee

            if token.type.isNative {
                switch sendAmount {
                case .max:
                    finalAmount = max(0, finalAmount - estimatedFee)

                    if finalAmount == 0 {
                        throw TransactionError.insufficientTonBalance(balance: tonBalance)
                    }
                default:
                    if finalAmount + estimatedFee > tonBalance {
                        throw TransactionError.insufficientTonBalance(balance: tonBalance)
                    }
                }
            } else {
                if tonBalance < estimatedFee {
                    throw TransactionError.insufficientTonBalance(balance: estimatedFee)
                }
            }
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            amount: finalAmount,
            address: address,
            memo: memo,
            fee: fee,
            transactionError: transactionError,
            sendAmount: sendAmount
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        _ = try await adapter.send(
            recipient: data.address,
            amount: data.sendAmount,
            comment: data.memo
        )
    }
}

extension TonSendHandler {
    class SendData: ISendData {
        private let token: Token
        private let amount: Decimal
        let address: FriendlyAddress
        let memo: String?
        private let fee: Decimal?
        private let transactionError: Error?
        let sendAmount: TonAdapter.SendAmount

        init(token: Token, amount: Decimal, address: FriendlyAddress, memo: String?, fee: Decimal?, transactionError: Error?, sendAmount: TonAdapter.SendAmount) {
            self.token = token
            self.amount = amount
            self.address = address
            self.memo = memo
            self.fee = fee
            self.transactionError = transactionError
            self.sendAmount = sendAmount
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

        private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let tonError = transactionError as? TonSendHandler.TransactionError {
                switch tonError {
                case let .insufficientTonBalance(balance):
                    let coinValue = CoinValue(kind: .token(token: feeToken), value: balance)
                    let balanceString = ValueFormatter.instance.formatShort(coinValue: coinValue)

                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
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

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
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
                    value: address.toString(),
                    blockchainType: .ton
                ),
            ]

            if let memo {
                fields.append(.levelValue(title: "send.confirmation.memo".localized, value: memo, level: .regular))
            }

            return [
                fields,
                feeFields(currency: currency, feeToken: baseToken, feeTokenRate: rates[token.coin.uid]),
            ]
        }

        private func feeFields(currency: Currency, feeToken: Token, feeTokenRate: Decimal?) -> [SendField] {
            var viewItems = [SendField]()

            if let fee {
                let coinValue = CoinValue(kind: .token(token: feeToken), value: fee)
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

extension TonSendHandler {
    enum SendError: Error {
        case invalidAmount
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientTonBalance(balance: Decimal)
    }
}

extension TonSendHandler {
    static func instance(token: Token, amount: Decimal, address: FriendlyAddress, memo: String?) -> TonSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: .ton, tokenType: .native)) else {
            return nil
        }

        guard let adapter = App.shared.adapterManager.adapter(for: token) as? ISendTonAdapter & IBalanceAdapter else {
            return nil
        }

        guard let tonKit = App.shared.tonKitManager.tonKit else {
            return nil
        }

        return TonSendHandler(
            tonKit: tonKit,
            token: token,
            baseToken: baseToken,
            adapter: adapter,
            amount: amount,
            address: address,
            memo: memo
        )
    }
}
