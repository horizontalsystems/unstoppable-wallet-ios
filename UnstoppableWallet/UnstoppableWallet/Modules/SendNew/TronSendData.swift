import BigInt
import Foundation
import MarketKit
import TronKit

class TronSendData: ISendData {
    let token: Token
    let baseToken: Token
    let decoration: TransactionDecoration?
    let contract: Contract?
    let rateCoins: [Coin]
    let transactionError: Error?
    let fees: [Fee]?
    let totalFees: Int?

    init(token: Token, baseToken: Token, decoration: TransactionDecoration?, contract: Contract?, rateCoins: [Coin], transactionError: Error?, fees: [Fee]?, totalFees: Int?) {
        self.token = token
        self.baseToken = baseToken
        self.decoration = decoration
        self.contract = contract
        self.rateCoins = rateCoins
        self.transactionError = transactionError
        self.fees = fees
        self.totalFees = totalFees
    }

    var feeData: FeeData? {
        fees.map { .tron(fees: $0) }
    }

    var canSend: Bool {
        fees != nil && transactionError == nil
    }

    var customSendButtonTitle: String? {
        nil
    }

    private func feeFields(currency: Currency, feeTokenRate: Decimal?) -> [SendField] {
        var viewItems = [SendField]()

        if let totalFees {
            let decimalAmount = Decimal(totalFees) / pow(10, baseToken.decimals)
            let appValue = AppValue(token: baseToken, value: decimalAmount)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: decimalAmount * $0) }

            viewItems.append(
                .value(
                    title: "fee_settings.network_fee".localized,
                    description: .init(title: "fee_settings.network_fee".localized, description: "fee_settings.network_fee.info".localized),
                    appValue: appValue,
                    currencyValue: currencyValue,
                    formatFull: true
                )
            )
        }

        if let fees {
            var bandwidth: String?
            var energy: String?

            for fee in fees {
                switch fee {
                case let .accountActivation(amount):
                    let decimalAmount = Decimal(amount) / pow(10, baseToken.decimals)
                    let appValue = AppValue(token: baseToken, value: decimalAmount)
                    let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: decimalAmount * $0) }

                    viewItems.append(
                        .value(
                            title: "tron.send.activation_fee".localized,
                            description: .init(title: "tron.send.activation_fee".localized, description: "tron.send.activation_fee.info".localized),
                            appValue: appValue,
                            currencyValue: currencyValue,
                            formatFull: true
                        )
                    )

                case let .bandwidth(points, _):
                    bandwidth = ValueFormatter.instance.formatShort(value: Decimal(points), decimalCount: 0)

                case let .energy(required, _):
                    energy = ValueFormatter.instance.formatShort(value: Decimal(required), decimalCount: 0)
                }
            }

            if bandwidth != nil || energy != nil {
                viewItems.append(
                    .doubleValue(
                        title: "tron.send.resources_consumed".localized,
                        description: .init(title: "tron.send.resources_consumed".localized, description: "tron.send.resources_consumed.info".localized),
                        value1: bandwidth.flatMap { "\($0) \("tron.send.bandwidth".localized)" } ?? "",
                        value2: energy.flatMap { "\($0) \("tron.send.energy".localized)" }
                    )
                )
            }
        }

        return viewItems
    }

    private func decorationSections(currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
        guard let decoration else {
            return []
        }

        switch decoration {
        case let decoration as NativeTransactionDecoration:
            guard let transfer = decoration.contract as? TransferContract else {
                return []
            }

            return sendFields(
                to: transfer.toAddress,
                value: Decimal(transfer.amount) / pow(10, token.decimals),
                currency: currency,
                rate: rates[token.coin.uid]
            )

        case let decoration as OutgoingEip20Decoration:
            return sendFields(
                to: decoration.to,
                value: Decimal(bigUInt: decoration.value, decimals: token.decimals) ?? 0,
                currency: currency,
                rate: rates[token.coin.uid]
            )

        default:
            return []
        }
    }

    private func sendFields(to: TronKit.Address, value: Decimal, currency: Currency, rate: Decimal?) -> [[SendField]] {
        let appValue = AppValue(token: token, value: Decimal(sign: .plus, exponent: value.exponent, significand: value.significand))

        return [[
            .amount(
                title: "send.confirmation.you_send".localized,
                token: token,
                appValueType: appValue.isMaxValue ? .infinity(code: appValue.code) : .regular(appValue: appValue),
                currencyValue: appValue.isMaxValue ? nil : rate.map { CurrencyValue(currency: currency, value: $0 * value) },
                type: .neutral
            ),
            .address(
                title: "send.confirmation.to".localized,
                value: to.base58,
                blockchainType: token.blockchainType
            ),
        ]]
    }

    func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let tronError = transactionError as? TronSendHandler.TransactionError {
            switch tronError {
            case let .insufficientBalance(balance):
                let appValue = AppValue(token: feeToken, value: balance.toDecimal(decimals: feeToken.decimals) ?? 0)
                let balanceString = appValue.formattedShort()

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
        var sections = decorationSections(currency: currency, rates: rates)

        sections.append(feeFields(currency: currency, feeTokenRate: rates[baseToken.coin.uid]))

        return sections
    }
}
