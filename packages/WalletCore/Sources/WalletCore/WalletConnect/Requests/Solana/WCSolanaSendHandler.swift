import Foundation
import HsCryptoKit
import MarketKit
import SolanaKit
import WalletConnectSign

class WCSolanaSendHandler {
    private let payload: WCSolanaTransactionPayload
    private let request: WCRequest
    private let solanaKit: SolanaKit.Kit
    private let signer: SolanaKit.Signer
    private let responder: WCResponder
    private let accountName: String?

    let baseToken: Token

    init(payload: WCSolanaTransactionPayload, request: WCRequest, baseToken: Token, solanaKit: SolanaKit.Kit, signer: SolanaKit.Signer, responder: WCResponder, accountName: String?) {
        self.accountName = accountName
        self.payload = payload
        self.request = request
        self.baseToken = baseToken
        self.solanaKit = solanaKit
        self.signer = signer
        self.responder = responder
    }
}

extension WCSolanaSendHandler: ISendHandler {
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        makeSendData()
    }

    // Fully synchronous (fee is a local compute, balance is cached), so the preview and the real send
    // produce the same data — the sheet opens complete with no spinner or resize.
    private func makeSendData() -> ISendData {
        let fees = payload.rawTransactions.compactMap { try? SolanaKit.Kit.estimateFee(rawTransaction: $0) }
        let fee: Decimal? = fees.count == payload.rawTransactions.count ? fees.reduce(0, +) : nil

        var transactionError: Error?
        if !payload.isSignOnly, let fee, solanaKit.balance < fee {
            transactionError = TransactionError.insufficientBalance(balance: solanaKit.balance)
        }

        let inner = WCSolanaSendData(token: baseToken, payload: payload, fee: fee, transactionError: transactionError)
        return WCSendData(inner: inner, request: request, accountName: accountName)
    }

    func send(data _: ISendData) async throws {
        try request.checkExpiration()
        guard !request.isBlocked else { throw SendError.blocked }
        switch payload.method {
        case WCSolanaTransactionPayload.signMethod:
            guard let raw = payload.rawTransactions.first else {
                throw SendError.invalidData
            }
            let signed = try SolanaKit.Kit.sign(rawTransaction: raw, signer: signer)
            let result = ["transaction": signed.transaction.base64EncodedString(), "signature": HsCryptoKit.Base58.encode(signed.signature)]
            try await responder.respond(request: payload, result: AnyCodable(any: result))

        case WCSolanaTransactionPayload.signAllMethod:
            let signed = try payload.rawTransactions.map { try SolanaKit.Kit.sign(rawTransaction: $0, signer: signer).transaction.base64EncodedString() }
            try await responder.respond(request: payload, result: AnyCodable(any: ["transactions": signed]))

        case WCSolanaTransactionPayload.signAndSendMethod:
            guard let raw = payload.rawTransactions.first else {
                throw SendError.invalidData
            }
            // the kit's broadcast path signs the fee-payer slot only
            guard payload.requiredSigners.first?.first == signer.address.base58 else {
                throw SendError.walletIsNotFeePayer
            }
            let fullTransaction = try await solanaKit.sendRawTransaction(rawTransaction: raw, signer: signer)
            try await responder.respond(request: payload, result: AnyCodable(any: ["signature": fullTransaction.transaction.hash]))

        default:
            throw SendError.invalidData
        }
    }
}

extension WCSolanaSendHandler: IWCPreviewSendHandler {
    func previewSendData() -> ISendData? {
        makeSendData()
    }
}

extension WCSolanaSendHandler {
    enum SendError: Error {
        case blocked
        case invalidData
        case walletIsNotFeePayer
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
    }
}
