import Foundation
import ZcashLightClientKit

enum ZcashResendModule {
    static func present(adapter: ITransactionsAdapter, transactionRecord: TransactionRecord, onSuccess: @escaping () -> Void) throws {
        let sendData = try sendData(adapter: adapter, transactionRecord: transactionRecord)
        let address = try address(transactionRecord: transactionRecord)

        Coordinator.shared.present { isPresented in
            RegularSendViewWrapper(
                sendData: sendData,
                address: address,
                isPresented: isPresented,
                onSuccess: onSuccess
            )
        }
    }

    private static func sendData(adapter: ITransactionsAdapter, transactionRecord: TransactionRecord) throws -> SendData {
        guard let zcashAdapter = adapter as? ZcashAdapter else {
            throw AppError.unknownError
        }

        let address = try address(transactionRecord: transactionRecord)
        guard let recipient = zcashAdapter.recipient(from: address) else {
            throw AppError.addressInvalid
        }

        let marginalFee = Zatoshi(ZcashAdapter.defaultZip317MarginalFee.amount * 4)
        return try .zcashResend(
            amount: amount(transactionRecord: transactionRecord),
            recipient: recipient,
            memo: (transactionRecord as? BitcoinTransactionRecord)?.memo,
            initialTransactionSettings: .zcash(
                zip317MarginalFee: marginalFee
            )
        )
    }

    private static func address(transactionRecord: TransactionRecord) throws -> String {
        guard let record = transactionRecord as? BitcoinOutgoingTransactionRecord, let address = record.to else {
            throw AppError.addressInvalid
        }

        return address
    }

    private static func amount(transactionRecord: TransactionRecord) throws -> Decimal {
        guard let record = transactionRecord as? BitcoinOutgoingTransactionRecord else {
            throw AppError.unknownError
        }

        return abs(record.value.value)
    }
}
