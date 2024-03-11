import BigInt
import Eip20Kit
import EvmKit
import Foundation
import MarketKit

class SendEvmHandler {
    let coinServiceFactory: EvmCoinServiceFactory
    let transactionData: TransactionData
    let evmKitWrapper: EvmKitWrapper

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
        let decoration = evmKitWrapper.evmKit.decorate(transactionData: transactionData)

        let gasPrice = transactionSettings?.gasPrice
        var gasLimit: Int?
        var transactionError: Error?

        if let gasPrice {
            do {
                gasLimit = try await evmKitWrapper.evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
            } catch {
                transactionError = error
            }
        }

        let sections = decoration.map { self.sections(decoration: $0) } ?? []

        return ConfirmationData(baseSections: sections, gasPrice: gasPrice, gasLimit: gasLimit, nonce: transactionSettings?.nonce, transactionError: transactionError)
    }

    func send(data: ISendConfirmationData) async throws {
        guard let data = data as? ConfirmationData else {
            throw SendError.invalidData
        }

        guard let gasPrice = data.gasPrice else {
            throw SendError.noGasPrice
        }

        guard let gasLimit = data.gasLimit else {
            throw SendError.noGasLimit
        }

        _ = try await evmKitWrapper.send(
            transactionData: transactionData,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            nonce: data.nonce
        )
    }

    private func sections(decoration: TransactionDecoration?) -> [[SendConfirmField]] {
        switch decoration {
        case let decoration as ApproveEip20Decoration:
            return eip20ApproveItems(
                spender: decoration.spender,
                value: decoration.value,
                contractAddress: decoration.contractAddress
            )
        default:
            return []
        }
    }

    private func eip20ApproveItems(spender: EvmKit.Address, value: BigUInt, contractAddress: EvmKit.Address) -> [[SendConfirmField]] {
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

        init(baseSections: [[SendConfirmField]], gasPrice: GasPrice?, gasLimit: Int?, nonce: Int?, transactionError: Error?) {
            self.baseSections = baseSections
            self.transactionError = transactionError

            super.init(gasPrice: gasPrice, gasLimit: gasLimit, nonce: nonce)
        }

        var feeData: FeeData? {
            gasLimit.map {
                .evm(gasLimit: $0)
            }
        }

        var canSend: Bool {
            gasLimit != nil
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
