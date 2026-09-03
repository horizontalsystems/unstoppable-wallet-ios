import Foundation
import HsCryptoKit
import MarketKit
import SolanaKit
import WalletConnectSign

class WCNSolanaSendHandler {
    private let parsed: WCNSolanaTransactionParsed
    private let request: WCNRequest
    private let solanaKit: SolanaKit.Kit
    private let signer: SolanaKit.Signer
    private let responder: WCNResponder

    let baseToken: Token

    init(parsed: WCNSolanaTransactionParsed, request: WCNRequest, baseToken: Token, solanaKit: SolanaKit.Kit, signer: SolanaKit.Signer, responder: WCNResponder) {
        self.parsed = parsed
        self.request = request
        self.baseToken = baseToken
        self.solanaKit = solanaKit
        self.signer = signer
        self.responder = responder
    }
}

extension WCNSolanaSendHandler: ISendHandler {
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let fees = parsed.rawTransactions.compactMap { try? SolanaKit.Kit.estimateFee(rawTransaction: $0) }
        let fee: Decimal? = fees.count == parsed.rawTransactions.count ? fees.reduce(0, +) : nil

        var transactionError: Error?
        if !parsed.isSignOnly, let fee, solanaKit.balance < fee {
            transactionError = TransactionError.insufficientBalance(balance: solanaKit.balance)
        }

        let inner = WCNSolanaSendData(token: baseToken, parsed: parsed, fee: fee, transactionError: transactionError)
        return WCNSendData(inner: inner, request: request)
    }

    func send(data _: ISendData) async throws {
        switch parsed.method {
        case WCNSolanaTransactionParsed.signMethod:
            guard let raw = parsed.rawTransactions.first else {
                throw SendError.invalidData
            }
            let signed = try SolanaKit.Kit.sign(rawTransaction: raw, signer: signer)
            let result = ["transaction": signed.transaction.base64EncodedString(), "signature": HsCryptoKit.Base58.encode(signed.signature)]
            try await responder.respond(request: parsed, result: AnyCodable(result))

        case WCNSolanaTransactionParsed.signAllMethod:
            let signed = try parsed.rawTransactions.map { try SolanaKit.Kit.sign(rawTransaction: $0, signer: signer).transaction.base64EncodedString() }
            try await responder.respond(request: parsed, result: AnyCodable(["transactions": signed]))

        case WCNSolanaTransactionParsed.signAndSendMethod:
            guard let raw = parsed.rawTransactions.first else {
                throw SendError.invalidData
            }
            // the kit's broadcast path signs the fee-payer slot only
            guard parsed.requiredSigners.first?.first == signer.address.base58 else {
                throw SendError.walletIsNotFeePayer
            }
            let fullTransaction = try await solanaKit.sendRawTransaction(rawTransaction: raw, signer: signer)
            try await responder.respond(request: parsed, result: AnyCodable(["signature": fullTransaction.transaction.hash]))

        default:
            throw SendError.invalidData
        }
    }
}

extension WCNSolanaSendHandler {
    enum SendError: Error {
        case invalidData
        case walletIsNotFeePayer
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
    }
}
