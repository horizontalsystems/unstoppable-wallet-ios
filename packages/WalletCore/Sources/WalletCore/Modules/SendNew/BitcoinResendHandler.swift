import BitcoinCore
import Foundation
import MarketKit

class BitcoinResendHandler: SendHandler {
    private let request: BitcoinResendRequest
    private var lastRecord: BitcoinOutgoingTransactionRecord
    private let buildReplacement: (Int) throws -> (ReplacementTransaction, BitcoinTransactionRecord)
    private let sendReplacement: (ReplacementTransaction) throws -> Void

    init(request: BitcoinResendRequest,
         buildReplacement: @escaping (Int) throws -> (ReplacementTransaction, BitcoinTransactionRecord),
         sendReplacement: @escaping (ReplacementTransaction) throws -> Void)
    {
        self.request = request
        lastRecord = request.transaction
        self.buildReplacement = buildReplacement
        self.sendReplacement = sendReplacement
    }

    override class func instance(sendData: SendData) -> ISendHandler? {
        guard case let .bitcoinResend(request) = sendData,
              [.bitcoin, .litecoin].contains(request.token.blockchainType),
              let adapter = Core.shared.adapterManager.adapter(for: request.token) as? BitcoinBaseAdapter
        else { return nil }

        return BitcoinResendHandler(request: request) { minFee in
            switch request.type {
            case .speedUp: return try adapter.speedUpTransaction(transactionHash: request.transaction.transactionHash, minFee: minFee)
            case .cancel: return try adapter.cancelTransaction(transactionHash: request.transaction.transactionHash, minFee: minFee)
            }
        } sendReplacement: { replacement in
            _ = try adapter.send(replacementTransaction: replacement)
        }
    }
}

extension BitcoinResendHandler: ISendHandler {
    var baseToken: Token { request.token }

    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData {
        guard case let .bitcoinResend(minFee, recommendedFee) = transactionSettings else {
            return BitcoinResendData(record: lastRecord, type: request.type)
        }

        do {
            let (replacement, record) = try buildReplacement(minFee)
            guard let record = record as? BitcoinOutgoingTransactionRecord else {
                throw ReplacementTransactionBuildError.unableToReplace
            }
            lastRecord = record
            return BitcoinResendData(record: record, type: request.type, recommendedFee: recommendedFee, replacement: replacement)
        } catch {
            // Keep the form and inline fee editor available when the kit rejects a fee.
            return BitcoinResendData(record: lastRecord, type: request.type, transactionError: error)
        }
    }

    func send(data: ISendData) async throws {
        guard let data = data as? BitcoinResendData, data.canSend, let replacement = data.replacement else {
            throw ReplacementTransactionBuildError.unableToReplace
        }
        try sendReplacement(replacement)
    }
}
