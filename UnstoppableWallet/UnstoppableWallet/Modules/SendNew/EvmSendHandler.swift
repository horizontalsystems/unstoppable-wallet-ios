import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class EvmSendHandler {
    let coinServiceFactory: EvmCoinServiceFactory
    let transactionData: TransactionData
    let evmKitWrapper: EvmKitWrapper
    let evmFeeEstimator = EvmFeeEstimator()

    init(coinServiceFactory: EvmCoinServiceFactory, transactionData: TransactionData, evmKitWrapper: EvmKitWrapper) {
        self.coinServiceFactory = coinServiceFactory
        self.transactionData = transactionData
        self.evmKitWrapper = evmKitWrapper
    }
}

extension EvmSendHandler: ISendHandler {
    var blockchainType: BlockchainType {
        evmKitWrapper.blockchainType
    }

    var syncingText: String? {
        nil
    }

    var expirationDuration: Int {
        10
    }

    func confirmationData(transactionSettings: TransactionSettings?) async throws -> ISendConfirmationData {
        let gasPrice = transactionSettings?.gasPrice
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let gasPrice {
            do {
                evmFeeData = try await evmFeeEstimator.estimateFee(evmKitWrapper: evmKitWrapper, transactionData: transactionData, gasPrice: gasPrice)
            } catch {
                transactionError = error
            }
        }

        let decoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let (sections, sendButtonTitle, sendingButtonTitle, sentButtonTitle) = resolve(decoration: decoration)

        return ConfirmationData(
            baseSections: sections,
            transactionError: transactionError,
            sendButtonTitle: sendButtonTitle,
            sendingButtonTitle: sendingButtonTitle,
            sentButtonTitle: sentButtonTitle,
            gasPrice: gasPrice,
            evmFeeData: evmFeeData,
            nonce: transactionSettings?.nonce
        )
    }

    func send(data: ISendConfirmationData) async throws {
        guard let data = data as? ConfirmationData else {
            throw SendError.invalidData
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

    private func resolve(decoration: TransactionDecoration?) -> ([[SendConfirmField]], String, String, String) {
        let sections: [[SendConfirmField]]
        var sendButtonTitle = "send.confirmation.slide_to_send".localized
        var sendingButtonTitle = "send.confirmation.sending".localized
        var sentButtonTitle = "send.confirmation.sent".localized

        switch decoration {
        case let decoration as OutgoingDecoration:
            sections = sendBaseCoinSections(
                to: decoration.to,
                value: decoration.value
            )
        case let decoration as OutgoingEip20Decoration:
            sections = eip20TransferSections(
                to: decoration.to,
                value: decoration.value,
                contractAddress: decoration.contractAddress
            )
        case let decoration as ApproveEip20Decoration:
            sections = eip20ApproveSections(
                spender: decoration.spender,
                value: decoration.value,
                contractAddress: decoration.contractAddress
            )

            let isRevoke = decoration.value == 0

            sendButtonTitle = isRevoke ? "send.confirmation.slide_to_revoke".localized : "send.confirmation.slide_to_approve".localized
            sendingButtonTitle = isRevoke ? "send.confirmation.revoking".localized : "send.confirmation.approving".localized
            sentButtonTitle = isRevoke ? "send.confirmation.revoked".localized : "send.confirmation.approved".localized
        default:
            sections = []
        }

        return (sections, sendButtonTitle, sendingButtonTitle, sentButtonTitle)
    }

    private func sendBaseCoinSections(to: EvmKit.Address, value: BigUInt) -> [[SendConfirmField]] {
        let coinService = coinServiceFactory.baseCoinService

        return [
            [
                amountField(
                    coinService: coinService,
                    title: "send.confirmation.you_send".localized,
                    value: value,
                    type: .neutral
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: to.eip55,
                    blockchainType: coinService.token.blockchainType
                ),
            ],
        ]
    }

    private func eip20TransferSections(to: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address) -> [[SendConfirmField]] {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return []
        }

        return [
            [
                amountField(
                    coinService: coinService,
                    title: "send.confirmation.you_send".localized,
                    value: value,
                    type: .neutral
                ),
                .address(
                    title: "send.confirmation.to".localized,
                    value: to.eip55,
                    blockchainType: coinService.token.blockchainType
                ),
            ],
        ]
    }

    private func eip20ApproveSections(spender: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address) -> [[SendConfirmField]] {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return []
        }

        let isRevokeAllowance = value == 0 // Check approved new value or revoked last allowance

        let amountField: SendConfirmField

        if isRevokeAllowance {
            amountField = .amount(
                title: "approve.confirmation.you_revoke".localized,
                token: coinService.token,
                coinValueType: .withoutAmount(kind: .token(token: coinService.token)),
                currencyValue: nil,
                type: .neutral
            )
        } else {
            amountField = self.amountField(
                coinService: coinService,
                title: "approve.confirmation.you_approve".localized,
                value: value,
                type: .neutral
            )
        }

        return [
            [
                amountField,
                .address(
                    title: "approve.confirmation.spender".localized,
                    value: spender.eip55,
                    blockchainType: coinService.token.blockchainType
                ),
            ],
        ]
    }

    private func amountField(coinService: CoinService, title: String, value: BigUInt, type: SendConfirmField.AmountType) -> SendConfirmField {
        amountField(coinService: coinService, title: title, amountData: coinService.amountData(value: value, sign: type.sign), type: type)
    }

    private func amountField(coinService: CoinService, title: String, amountData: AmountData, type: SendConfirmField.AmountType) -> SendConfirmField {
        let token = coinService.token
        let value = amountData.coinValue

        return .amount(
            title: title,
            token: token,
            coinValueType: value.isMaxValue ? .infinity(kind: value.kind) : .regular(coinValue: value),
            currencyValue: value.isMaxValue ? nil : amountData.currencyValue,
            type: type
        )
    }
}

extension EvmSendHandler {
    class ConfirmationData: BaseSendEvmData, ISendConfirmationData {
        let baseSections: [[SendConfirmField]]
        let transactionError: Error?
        let sendButtonTitle: String
        let sendingButtonTitle: String
        let sentButtonTitle: String

        init(baseSections: [[SendConfirmField]], transactionError: Error?, sendButtonTitle: String, sendingButtonTitle: String, sentButtonTitle: String, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
            self.baseSections = baseSections
            self.transactionError = transactionError
            self.sendButtonTitle = sendButtonTitle
            self.sendingButtonTitle = sendingButtonTitle
            self.sentButtonTitle = sentButtonTitle

            super.init(gasPrice: gasPrice, evmFeeData: evmFeeData, nonce: nonce)
        }

        var feeData: FeeData? {
            evmFeeData.map { .evm(evmFeeData: $0) }
        }

        var canSend: Bool {
            evmFeeData != nil
        }

        func cautions(feeToken: Token?) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(caution(transactionError: transactionError, feeToken: feeToken))
            }

            return cautions
        }

        func sections(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
            var sections = baseSections

            if let nonce {
                sections.append(
                    [
                        .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                    ]
                )
            }

            if let feeToken {
                sections.append(feeFields(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate))
            }

            return sections
        }
    }
}

extension EvmSendHandler {
    enum SendError: Error {
        case invalidData
        case noGasPrice
        case noGasLimit
    }
}

extension EvmSendHandler {
    static func instance(blockchainType: BlockchainType, transactionData: TransactionData) -> EvmSendHandler? {
        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: blockchainType,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: blockchainType).evmKitWrapper else {
            return nil
        }

        return EvmSendHandler(
            coinServiceFactory: coinServiceFactory,
            transactionData: transactionData,
            evmKitWrapper: evmKitWrapper
        )
    }
}
