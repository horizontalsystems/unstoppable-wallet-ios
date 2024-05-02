import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class EvmSendHandler {
    let coinManager = App.shared.coinManager
    let evmLabelManager = App.shared.evmLabelManager

    let baseToken: Token
    let transactionData: TransactionData
    let evmKitWrapper: EvmKitWrapper
    let evmFeeEstimator = EvmFeeEstimator()

    init(baseToken: Token, transactionData: TransactionData, evmKitWrapper: EvmKitWrapper) {
        self.baseToken = baseToken
        self.transactionData = transactionData
        self.evmKitWrapper = evmKitWrapper
    }

    private func decorate(transactionData: TransactionData, transactionDecoration: TransactionDecoration?) -> Decoration {
        var type: Decoration.`Type`?
        var customSendButtonTitle: String?

        switch transactionDecoration {
        case let decoration as OutgoingDecoration:
            type = .outgoingEvm(
                to: decoration.to,
                value: baseToken.decimalValue(value: decoration.value)
            )

        case let decoration as OutgoingEip20Decoration:
            if let token = try? coinManager.token(query: .init(blockchainType: baseToken.blockchainType, tokenType: .eip20(address: decoration.contractAddress.hex))) {
                type = .outgoingEip20(
                    to: decoration.to,
                    value: token.decimalValue(value: decoration.value),
                    token: token
                )
            }

        case let decoration as ApproveEip20Decoration:
            if let token = try? coinManager.token(query: .init(blockchainType: baseToken.blockchainType, tokenType: .eip20(address: decoration.contractAddress.hex))) {
                type = .approveEip20(
                    spender: decoration.spender,
                    value: token.decimalValue(value: decoration.value),
                    token: token
                )

                let isRevoke = decoration.value == 0

                customSendButtonTitle = isRevoke ? "send.confirmation.slide_to_revoke".localized : "send.confirmation.slide_to_approve".localized
            }
        default:
            ()
        }

        return Decoration(
            type: type ?? .unknown(
                to: transactionData.to,
                value: baseToken.decimalValue(value: transactionData.value),
                input: transactionData.input,
                method: evmLabelManager.methodLabel(input: transactionData.input)
            ),
            customSendButtonTitle: customSendButtonTitle
        )
    }
}

extension EvmSendHandler: ISendHandler {
    var syncingText: String? {
        nil
    }

    var expirationDuration: Int {
        10
    }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        let gasPrice = transactionSettings?.gasPrice
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        var transactionData = transactionData

        if let gasPrice {
            let evmBalance = evmKitWrapper.evmKit.accountState?.balance ?? 0

            do {
                if transactionData.input.isEmpty, transactionData.value == evmBalance {
                    let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: transactionData.input)
                    let stubFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: stubTransactionData, gasPrice: gasPrice)
                    let totalFee = stubFeeData.totalFee(gasPrice: gasPrice)

                    evmFeeData = stubFeeData
                    transactionData = TransactionData(to: transactionData.to, value: max(0, transactionData.value - totalFee), input: transactionData.input)
                } else {
                    evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPrice: gasPrice)
                }
            } catch {
                transactionError = error
            }
        }

        let transactionDecoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let decoration = decorate(transactionData: transactionData, transactionDecoration: transactionDecoration)

        return SendData(
            decoration: decoration,
            transactionData: transactionData,
            transactionError: transactionError,
            gasPrice: gasPrice,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        guard let transactionData = data.transactionData else {
            throw SendError.noTransactionData
        }

        guard let gasPrice = data.gasPrice else {
            throw SendError.noGasPrice
        }

        guard let gasLimit = data.evmFeeData?.surchargedGasLimit else {
            throw SendError.noGasLimit
        }

        _ = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: data.nonce
        )
    }
}

extension EvmSendHandler {
    class SendData: BaseSendEvmData, ISendData {
        let decoration: Decoration
        let transactionData: TransactionData?
        let transactionError: Error?

        init(decoration: Decoration, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
            self.decoration = decoration
            self.transactionData = transactionData
            self.transactionError = transactionError

            super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
        }

        var feeData: FeeData? {
            evmFeeData.map { .evm(evmFeeData: $0) }
        }

        var canSend: Bool {
            evmFeeData != nil
        }

        var rateCoins: [Coin] {
            decoration.rateCoins
        }

        var customSendButtonTitle: String? {
            decoration.customSendButtonTitle
        }

        func cautions(baseToken: Token) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
            }

            return cautions
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            var sections: [[SendField]]

            switch decoration.type {
            case let .outgoingEvm(to, value):
                sections = outgoingSections(token: baseToken, to: to, value: value, currency: currency, rates: rates)
            case let .outgoingEip20(to, value, token):
                sections = outgoingSections(token: token, to: to, value: value, currency: currency, rates: rates)
            case let .approveEip20(spender, value, token):
                sections = approveSections(token: token, spender: spender, value: value, currency: currency, rates: rates)
            case let .unknown(to, value, input, method):
                sections = unknownSections(baseToken: baseToken, to: to, value: value, input: input, method: method, currency: currency, rates: rates)
            }

            if let nonce {
                sections.append(
                    [
                        .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                    ]
                )
            }

            sections.append(feeFields(feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid]))

            return sections
        }

        private func outgoingSections(token: Token, to: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            [
                [
                    amountField(
                        title: "send.confirmation.you_send".localized,
                        token: token,
                        value: value,
                        currency: currency,
                        rate: rates[token.coin.uid],
                        type: .neutral
                    ),
                    .address(
                        title: "send.confirmation.to".localized,
                        value: to.eip55,
                        blockchainType: token.blockchainType
                    ),
                ],
            ]
        }

        private func approveSections(token: Token, spender: EvmKit.Address, value: Decimal, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            let isRevokeAllowance = value == 0 // Check approved new value or revoked last allowance

            let amountField: SendField

            if isRevokeAllowance {
                amountField = .amount(
                    title: "approve.confirmation.you_revoke".localized,
                    token: token,
                    coinValueType: .withoutAmount(kind: .token(token: token)),
                    currencyValue: nil,
                    type: .neutral
                )
            } else {
                amountField = self.amountField(
                    title: "approve.confirmation.you_approve".localized,
                    token: token,
                    value: value,
                    currency: currency,
                    rate: rates[token.coin.uid],
                    type: .neutral
                )
            }

            return [
                [
                    amountField,
                    .address(
                        title: "approve.confirmation.spender".localized,
                        value: spender.eip55,
                        blockchainType: token.blockchainType
                    ),
                ],
            ]
        }

        private func unknownSections(baseToken: Token, to: EvmKit.Address, value: Decimal, input _: Data, method _: String?, currency: Currency, rates: [String: Decimal]) -> [[SendField]] {
            [
                [
                    amountField(
                        title: "send.confirmation.transfer".localized,
                        token: baseToken,
                        value: value,
                        currency: currency,
                        rate: rates[baseToken.coin.uid],
                        type: .neutral
                    ),
                    .address(
                        title: "send.confirmation.to".localized,
                        value: to.eip55,
                        blockchainType: baseToken.blockchainType
                    ),
                    // TODO: show input and method
                ],
            ]
        }

        private func amountField(title: String, token: Token, value: Decimal, currency: Currency, rate: Decimal?, type: SendField.AmountType) -> SendField {
            let coinValue = CoinValue(kind: .token(token: token), value: Decimal(sign: type.sign, exponent: value.exponent, significand: value.significand))

            return .amount(
                title: title,
                token: token,
                coinValueType: coinValue.isMaxValue ? .infinity(kind: coinValue.kind) : .regular(coinValue: coinValue),
                currencyValue: coinValue.isMaxValue ? nil : rate.map { CurrencyValue(currency: currency, value: $0 * value) },
                type: type
            )
        }
    }
}

extension EvmSendHandler {
    struct Decoration {
        let type: Type
        let customSendButtonTitle: String?

        enum `Type` {
            case outgoingEvm(to: EvmKit.Address, value: Decimal)
            case outgoingEip20(to: EvmKit.Address, value: Decimal, token: Token)
            case approveEip20(spender: EvmKit.Address, value: Decimal, token: Token)
            case unknown(to: EvmKit.Address, value: Decimal, input: Data, method: String?)
        }

        var rateCoins: [Coin] {
            switch type {
            case let .outgoingEip20(_, _, token): return [token.coin]
            case let .approveEip20(_, _, token): return [token.coin]
            default: return []
            }
        }
    }

    enum SendError: Error {
        case invalidData
        case noGasPrice
        case noGasLimit
        case noTransactionData
    }
}

extension EvmSendHandler {
    static func instance(blockchainType: BlockchainType, transactionData: TransactionData) -> EvmSendHandler? {
        guard let baseToken = try? App.shared.coinManager.token(query: .init(blockchainType: blockchainType, tokenType: .native)) else {
            return nil
        }

        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            return nil
        }

        return EvmSendHandler(
            baseToken: baseToken,
            transactionData: transactionData,
            evmKitWrapper: evmKitWrapper
        )
    }
}
