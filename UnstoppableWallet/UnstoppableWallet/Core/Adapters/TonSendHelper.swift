import BigInt
import Foundation
import MarketKit
import TonKit
import TonSwift

class TonSendHelper {
    struct EmulationResult {
        let fee: Decimal
        let totalValue: BigUInt
        let record: TonTransactionRecord?
    }

    static func transferData(
        param: SendTransactionParam,
        contract: WalletContract
    ) throws -> TransferData {
        let address = try contract.address()

        let payloads = param.messages.map { message in
            TonKit.Kit.Payload(
                value: BigInt(integerLiteral: message.amount),
                recipientAddress: message.address,
                bounceable: message.bounceable ?? true,
                stateInit: message.stateInit,
                payload: message.payload
            )
        }

        return try TonKit.Kit.transferData(
            sender: address,
            validUntil: param.validUntil,
            payloads: payloads
        )
    }

    static func emulate(
        transferData: TransferData,
        contract: WalletContract,
        converter: TonEventConverter?
    ) async throws -> EmulationResult {
        let result = try await TonKit.Kit.emulate(
            transferData: transferData,
            contract: contract,
            network: TonKitManager.network
        )

        let fee = TonAdapter.amount(kitAmount: result.totalFee)

        var totalValue: BigUInt = 0
        for message in transferData.internalMessages {
            switch message.info {
            case let .internalInfo(info):
                totalValue += info.value.coins.rawValue
            default: ()
            }
        }

        let record = converter?.transactionRecord(event: result.event)

        return EmulationResult(fee: fee, totalValue: totalValue, record: record)
    }

    static func validateBalance(
        address: TonSwift.Address,
        totalValue: BigUInt,
        fee: BigUInt
    ) async throws {
        let account = try await TonKit.Kit.account(address: address)

        guard account.balance >= totalValue + fee else {
            throw TransactionError.insufficientTonBalance(
                balance: TonAdapter.amount(kitAmount: account.balance)
            )
        }
    }

    static func send(
        transferData: TransferData,
        contract: WalletContract,
        secretKey: Data
    ) async throws -> String {
        let boc = try await TonKit.Kit.boc(
            transferData: transferData,
            contract: contract,
            secretKey: secretKey,
            network: TonKitManager.network
        )

        try await TonKit.Kit.send(
            boc: boc,
            contract: contract,
            network: TonKitManager.network
        )

        return boc
    }
}

// UI Part

extension TonSendHelper {
    static func caution(transactionError: Error, feeToken: Token) -> CautionNew {
        let title: String
        let text: String

        if let tonError = transactionError as? TransactionError {
            switch tonError {
            case let .insufficientTonBalance(balance):
                let appValue = AppValue(token: feeToken, value: balance)
                let balanceString = appValue.formattedShort()

                title = "fee_settings.errors.insufficient_balance".localized
                text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
            }
        } else {
            title = "ethereum_transaction.error.title".localized
            text = transactionError.convertedError.smartDescription
        }

        return CautionNew(title: title, text: text, type: .error)
    }

    static func feeFields(
        fee: Decimal?,
        feeToken: Token,
        currency: Currency,
        feeTokenRate: Decimal?
    ) -> [SendField] {
        var viewItems = [SendField]()

        if let fee {
            let appValue = AppValue(token: feeToken, value: fee)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

            viewItems.append(
                .value(
                    title: SendField.InformedTitle("fee_settings.network_fee".localized, info: .fee),
                    appValue: appValue,
                    currencyValue: currencyValue,
                    formatFull: true
                )
            )
        }

        return viewItems
    }
}

extension TonSendHelper {
    enum TransactionError: Error {
        case insufficientTonBalance(balance: Decimal)
    }
}
