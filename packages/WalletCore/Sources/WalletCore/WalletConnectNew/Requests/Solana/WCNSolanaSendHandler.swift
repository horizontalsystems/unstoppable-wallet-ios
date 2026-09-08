import Foundation
import HsCryptoKit
import MarketKit
import SolanaKit
import WalletConnectSign

class WCNSolanaSendHandler {
    private let payload: WCNSolanaTransactionPayload
    private let request: WCNRequest
    private let solanaKit: SolanaKit.Kit
    private let signer: SolanaKit.Signer
    private let responder: WCNResponder
    private let accountName: String?

    let baseToken: Token

    init(payload: WCNSolanaTransactionPayload, request: WCNRequest, baseToken: Token, solanaKit: SolanaKit.Kit, signer: SolanaKit.Signer, responder: WCNResponder, accountName: String?) {
        self.accountName = accountName
        self.payload = payload
        self.request = request
        self.baseToken = baseToken
        self.solanaKit = solanaKit
        self.signer = signer
        self.responder = responder
    }
}

extension WCNSolanaSendHandler: ISendHandler {
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let fees = payload.rawTransactions.compactMap { try? SolanaKit.Kit.estimateFee(rawTransaction: $0) }
        let fee: Decimal? = fees.count == payload.rawTransactions.count ? fees.reduce(0, +) : nil

        var transactionError: Error?
        if !payload.isSignOnly, let fee, solanaKit.balance < fee {
            transactionError = TransactionError.insufficientBalance(balance: solanaKit.balance)
        }

        let inner = WCNSolanaSendData(token: baseToken, payload: payload, fee: fee, transactionError: transactionError)
        return WCNSendData(inner: inner, request: request, accountName: accountName)
    }

    func send(data _: ISendData) async throws {
        guard !request.isBlocked else { throw SendError.blocked }
        switch payload.method {
        case WCNSolanaTransactionPayload.signMethod:
            guard let raw = payload.rawTransactions.first else {
                throw SendError.invalidData
            }
            let signed = try SolanaKit.Kit.sign(rawTransaction: raw, signer: signer)
            let result = ["transaction": signed.transaction.base64EncodedString(), "signature": HsCryptoKit.Base58.encode(signed.signature)]
            try await responder.respond(request: payload, result: AnyCodable(any: result))

        case WCNSolanaTransactionPayload.signAllMethod:
            let signed = try payload.rawTransactions.map { try SolanaKit.Kit.sign(rawTransaction: $0, signer: signer).transaction.base64EncodedString() }
            try await responder.respond(request: payload, result: AnyCodable(any: ["transactions": signed]))

        case WCNSolanaTransactionPayload.signAndSendMethod:
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

extension WCNSolanaSendHandler {
    enum SendError: Error {
        case blocked
        case invalidData
        case walletIsNotFeePayer
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
    }
}
