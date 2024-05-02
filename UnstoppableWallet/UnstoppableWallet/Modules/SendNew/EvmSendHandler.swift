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
    let decorator = EvmDecorator()
    let evmFeeEstimator = EvmFeeEstimator()

    init(baseToken: Token, transactionData: TransactionData, evmKitWrapper: EvmKitWrapper) {
        self.baseToken = baseToken
        self.transactionData = transactionData
        self.evmKitWrapper = evmKitWrapper
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
        let decoration = decorator.decorate(baseToken: baseToken, transactionData: transactionData, transactionDecoration: transactionDecoration)

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
        let decoration: EvmDecoration
        let transactionData: TransactionData?
        let transactionError: Error?

        init(decoration: EvmDecoration, transactionData: TransactionData?, transactionError: Error?, gasPrice: GasPrice?, evmFeeData: EvmFeeData?, nonce: Int?) {
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
            var sections = decoration.sections(baseToken: baseToken, currency: currency, rates: rates)

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
    }
}

extension EvmSendHandler {
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
