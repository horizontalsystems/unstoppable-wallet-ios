import Foundation
import MarketKit
import StellarKit
import stellarsdk
import WalletConnectSign

class WCStellarSendHandler {
    private let payload: WCStellarTransactionPayload
    private let request: WCRequest
    private let stellarKit: StellarKit.Kit
    private let keyPair: KeyPair
    private let responder: WCResponder
    private let accountName: String?

    let baseToken: Token

    init(payload: WCStellarTransactionPayload, request: WCRequest, baseToken: Token, stellarKit: StellarKit.Kit, keyPair: KeyPair, responder: WCResponder, accountName: String?) {
        self.accountName = accountName
        self.payload = payload
        self.request = request
        self.baseToken = baseToken
        self.stellarKit = stellarKit
        self.keyPair = keyPair
        self.responder = responder
    }
}

extension WCStellarSendHandler: ISendHandler {
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        guard let transaction = try? stellarKit.transaction(transactionEnvelope: payload.xdr) else {
            throw SendError.invalidData
        }

        if payload.isSignOnly {
            let inner = WCStellarSignData(xdr: payload.xdr, transaction: transaction, sourceAccountId: payload.from ?? "")
            return WCSendData(inner: inner, request: request, accountName: accountName)
        }

        let fee = Decimal(transaction.fee) / pow(10, baseToken.decimals)
        let balance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0
        let transactionError: Error? = balance < fee ? TransactionError.insufficientBalance(balance: balance) : nil

        let inner = WCStellarSubmitData(token: baseToken, xdr: payload.xdr, transaction: transaction, sourceAccountId: payload.from ?? "", fee: fee, transactionError: transactionError)
        return WCSendData(inner: inner, request: request, accountName: accountName)
    }

    func send(data: ISendData) async throws {
        guard !request.isBlocked else { throw SendError.blocked }
        switch (data as? WCSendData)?.inner {
        case let data as WCStellarSignData:
            let signedXdr = try StellarKit.Kit.sign(transactionEnvelope: data.xdr, keyPair: keyPair)
            try await responder.respond(request: payload, result: AnyCodable(["signedXDR": signedXdr]))
        case let data as WCStellarSubmitData:
            _ = try await StellarKit.Kit.send(transactionEnvelope: data.xdr, keyPair: keyPair)
            try await responder.respond(request: payload, result: AnyCodable(["status": "success"]))
        default:
            throw SendError.invalidData
        }
    }
}

extension WCStellarSendHandler {
    enum SendError: Error {
        case blocked
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
    }
}
