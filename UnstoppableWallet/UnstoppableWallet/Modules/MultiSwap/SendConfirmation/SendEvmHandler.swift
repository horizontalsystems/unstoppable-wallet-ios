import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class SendEvmHandler {
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

extension SendEvmHandler: ISendHandler {
    var blockchainType: BlockchainType {
        evmKitWrapper.blockchainType
    }

    func confirmationData(transactionSettings: TransactionSettings?) async throws -> ISendConfirmationData {
        let gasPrice = transactionSettings?.gasPrice
        var evmFeeData: EvmFeeData?
        var transactionError: Error?

        if let gasPrice {
            do {
                evmFeeData = try await evmFeeEstimator.estimateFee(blockchainType: blockchainType, evmKit: evmKitWrapper.evmKit, transactionData: transactionData, gasPrice: gasPrice)
            } catch {
                transactionError = error
            }
        }

        let decoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)
        let (sections, customSendButtonTitle, customSendingButtonTitle, customSentButtonTitle) = decoration.map { resolve(decoration: $0) } ?? ([], nil, nil, nil)

        return ConfirmationData(
            baseSections: sections,
            transactionError: transactionError,
            customSendButtonTitle: customSendButtonTitle,
            customSendingButtonTitle: customSendingButtonTitle,
            customSentButtonTitle: customSentButtonTitle,
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

        guard let gasLimit = data.evmFeeData?.gasLimit else {
            throw SendError.noGasLimit
        }

        _ = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: data.nonce
        )
    }

    private func resolve(decoration: TransactionDecoration?) -> ([[SendConfirmField]], String?, String?, String?) {
        switch decoration {
        case let decoration as ApproveEip20Decoration:
            let sections = eip20ApproveSections(
                spender: decoration.spender,
                value: decoration.value,
                contractAddress: decoration.contractAddress
            )

            let isRevoke = decoration.value == 0

            return (
                sections,
                isRevoke ? "send.confirmation.slide_to_revoke".localized : "send.confirmation.slide_to_approve".localized,
                isRevoke ? "send.confirmation.revoking".localized : "send.confirmation.approving".localized,
                isRevoke ? "send.confirmation.revoked".localized : "send.confirmation.approved".localized
            )
        default:
            return ([], nil, nil, nil)
        }
    }

    private func eip20ApproveSections(spender: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address) -> [[SendConfirmField]] {
        guard let coinService = coinServiceFactory.coinService(contractAddress: contractAddress) else {
            return []
        }

        var sections = [[SendConfirmField]]()

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

        sections.append([amountField])

        sections.append(
            [
                .address(
                    title: "approve.confirmation.spender".localized,
                    value: spender.eip55
                ),
            ]
        )

        return sections
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

extension SendEvmHandler {
    class ConfirmationData: BaseSendEvmData, ISendConfirmationData {
        let baseSections: [[SendConfirmField]]
        let transactionError: Error?
        let customSendButtonTitle: String?
        let customSendingButtonTitle: String?
        let customSentButtonTitle: String?

        init(baseSections: [[SendConfirmField]], transactionError: Error?, customSendButtonTitle: String?, customSendingButtonTitle: String?, customSentButtonTitle: String?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
            self.baseSections = baseSections
            self.transactionError = transactionError
            self.customSendButtonTitle = customSendButtonTitle
            self.customSendingButtonTitle = customSendingButtonTitle
            self.customSentButtonTitle = customSentButtonTitle

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
                sections.append(feeSection(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate))
            }

            return sections
        }
    }
}

extension SendEvmHandler {
    enum SendError: Error {
        case invalidData
        case noGasPrice
        case noGasLimit
    }
}

extension SendEvmHandler {
    static func instance(blockchainType: BlockchainType, transactionData: TransactionData) -> SendEvmHandler? {
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

        return SendEvmHandler(
            coinServiceFactory: coinServiceFactory,
            transactionData: transactionData,
            evmKitWrapper: evmKitWrapper
        )
    }
}
