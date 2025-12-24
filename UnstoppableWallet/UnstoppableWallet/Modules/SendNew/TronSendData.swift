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
                    title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
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

                    let info = InfoDescription(title: "tron.send.activation_fee".localized, description: "tron.send.activation_fee.info".localized)

                    viewItems.append(
                        .value(
                            title: SendField.InformedTitle("tron.send.activation_fee".localized, info: info),
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

    func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection? {
        switch decoration {
        case let decoration as NativeTransactionDecoration:
            guard let transfer = decoration.contract as? TransferContract else {
                return nil
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
            return nil
        }
    }

    private func decorationFields(currency: Currency, rates: [String: Decimal]) -> [SendField] {
        switch decoration {
        case let decoration as ApproveEip20Decoration:
            return approveFields(
                spender: decoration.spender,
                value: decoration.value,
                contractAddress: decoration.contractAddress,
                currency: currency,
                rates: rates
            )

        default:
            return []
        }
    }

    private func sendFields(to: TronKit.Address, value: Decimal, currency: Currency, rate: Decimal?) -> SendDataSection {
        let appValue = AppValue(token: token, value: Decimal(sign: .plus, exponent: value.exponent, significand: value.significand))

        return .init(
            [
                .amountNew(
                    token: token,
                    appValueType: appValue.isMaxValue ? .infinity(code: appValue.code) : .regular(appValue: appValue),
                    currencyValue: appValue.isMaxValue ? nil : rate.map { CurrencyValue(currency: currency, value: $0 * value) }
                ),
                .address(
                    value: to.base58,
                    blockchainType: token.blockchainType
                ),
            ],
            isFlow: true
        )
    }

    private func approveFields(spender: TronKit.Address, value: BigUInt, contractAddress: TronKit.Address, currency: Currency, rates: [String: Decimal]) -> [SendField] {
        guard
            let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: .tron,
                marketKit: Core.shared.marketKit,
                currencyManager: Core.shared.currencyManager,
                coinManager: Core.shared.coinManager
            ),
            let coinService = coinServiceFactory.coinService(contractAddress: contractAddress),
            let value = value.toDecimal(decimals: coinService.token.decimals)
        else {
            return []
        }

        let isRevokeAllowance = value == 0 // Check approved new value or revoked last allowance
        let approveValue = AppValue(token: coinService.token, value: value)

        var fields: [SendField] = []
        if isRevokeAllowance {
            fields.append(
                .amountNew(
                    token: coinService.token,
                    appValueType: .withoutAmount(code: coinService.token.coin.code),
                    currencyValue: nil,
                )
            )
        } else {
            fields.append(
                .amountNew(
                    token: coinService.token,
                    appValueType: approveValue.isMaxValue ? .infinity(code: approveValue.code) : .regular(appValue: approveValue),
                    currencyValue: approveValue.isMaxValue ? nil : rates[contractAddress.base58].map { CurrencyValue(currency: currency, value: $0 * value) },
                )
            )
        }

        fields.append(
            .address(
                value: spender.base58,
                blockchainType: coinService.token.blockchainType
            )
        )

        return fields
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

    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
        var sections = [SendDataSection]()
        if let flow = flowSection(baseToken: baseToken, currency: currency, rates: rates) {
            sections.append(flow)
        }

        let decorationFields = decorationFields(currency: currency, rates: rates)
        let feeFields = feeFields(currency: currency, feeTokenRate: rates[baseToken.coin.uid])

        sections.append(.init(decorationFields + feeFields))

        return sections
    }
}
