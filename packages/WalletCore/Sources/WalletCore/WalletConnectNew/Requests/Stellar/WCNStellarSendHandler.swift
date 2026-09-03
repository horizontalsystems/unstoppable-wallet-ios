import Foundation
import MarketKit
import StellarKit
import stellarsdk
import WalletConnectSign

class WCNStellarSendHandler {
    private let payload: WCNStellarTransactionPayload
    private let request: WCNRequest
    private let stellarKit: StellarKit.Kit
    private let keyPair: KeyPair
    private let responder: WCNResponder

    let baseToken: Token

    init(payload: WCNStellarTransactionPayload, request: WCNRequest, baseToken: Token, stellarKit: StellarKit.Kit, keyPair: KeyPair, responder: WCNResponder) {
        self.payload = payload
        self.request = request
        self.baseToken = baseToken
        self.stellarKit = stellarKit
        self.keyPair = keyPair
        self.responder = responder
    }
}

extension WCNStellarSendHandler: ISendHandler {
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        guard let transaction = try? stellarKit.transaction(transactionEnvelope: payload.xdr) else {
            throw SendError.invalidData
        }

        if payload.isSignOnly {
            let inner = WCNStellarSignData(xdr: payload.xdr, transaction: transaction, sourceAccountId: payload.from ?? "")
            return WCNSendData(inner: inner, request: request)
        }

        let fee = Decimal(transaction.fee) / pow(10, baseToken.decimals)
        let balance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0
        let transactionError: Error? = balance < fee ? TransactionError.insufficientBalance(balance: balance) : nil

        let inner = WCNStellarSubmitData(token: baseToken, xdr: payload.xdr, transaction: transaction, sourceAccountId: payload.from ?? "", fee: fee, transactionError: transactionError)
        return WCNSendData(inner: inner, request: request)
    }

    func send(data: ISendData) async throws {
        switch (data as? WCNSendData)?.inner {
        case let data as WCNStellarSignData:
            let signedXdr = try StellarKit.Kit.sign(transactionEnvelope: data.xdr, keyPair: keyPair)
            try await responder.respond(request: payload, result: AnyCodable(["signedXDR": signedXdr]))
        case let data as WCNStellarSubmitData:
            _ = try await StellarKit.Kit.send(transactionEnvelope: data.xdr, keyPair: keyPair)
            try await responder.respond(request: payload, result: AnyCodable(["status": "success"]))
        default:
            throw SendError.invalidData
        }
    }
}

extension WCNStellarSendHandler {
    enum SendError: Error {
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
    }
}
