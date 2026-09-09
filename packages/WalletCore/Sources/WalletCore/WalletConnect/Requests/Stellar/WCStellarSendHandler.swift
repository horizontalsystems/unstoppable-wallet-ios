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

        // the trustline pre-flight is the only async part; run it and fold it into the otherwise-sync build
        let trustlineError = payload.isSignOnly ? nil : await noTrustlineError(operations: transaction.operations)
        return makeSendData(transaction: transaction, extraError: trustlineError)
    }

    // Synchronous build (XDR parse, fee and reserve-aware balance are local), so the preview opens the
    // sheet complete; `extraError` carries the async trustline result (nil for the preview).
    private func makeSendData(transaction: stellarsdk.Transaction, extraError: Error?) -> ISendData {
        if payload.isSignOnly {
            let inner = WCStellarSignData(xdr: payload.xdr, transaction: transaction, sourceAccountId: payload.from ?? "")
            return WCSendData(inner: inner, request: request, accountName: accountName)
        }

        let fee = Decimal(transaction.fee) / pow(10, baseToken.decimals)
        // reserve-aware balance (matches StellarSendHelper), so the fee check can't pass while dipping
        // below the account's minimum-balance reserve
        let balance = stellarKit.account?.availableBalance ?? 0
        let transactionError: Error? = balance < fee ? TransactionError.insufficientBalance(balance: balance) : extraError

        let inner = WCStellarSubmitData(token: baseToken, xdr: payload.xdr, transaction: transaction, sourceAccountId: payload.from ?? "", fee: fee, transactionError: transactionError)
        return WCSendData(inner: inner, request: request, accountName: accountName)
    }

    // Pre-flight (mirrors StellarSendHelper.preparePayment): a payment of a non-native asset needs the
    // destination to already hold a trustline for it; Horizon rejects otherwise, so warn up front.
    private func noTrustlineError(operations: [stellarsdk.Operation]) async -> Error? {
        for case let payment as stellarsdk.PaymentOperation in operations {
            guard payment.asset.type != AssetType.ASSET_TYPE_NATIVE else { continue }
            let asset = StellarKit.Asset.asset(code: payment.asset.code ?? "", issuer: payment.asset.issuer?.accountId ?? "")
            let destination = try? await StellarKit.Kit.account(accountId: payment.destinationAccountId)
            if destination?.assetBalanceMap[asset] == nil {
                return TransactionError.noTrustline
            }
        }
        return nil
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

extension WCStellarSendHandler: IWCPreviewSendHandler {
    func previewSendData() -> ISendData? {
        guard let transaction = try? stellarKit.transaction(transactionEnvelope: payload.xdr) else {
            return nil
        }
        return makeSendData(transaction: transaction, extraError: nil)
    }
}

extension WCStellarSendHandler {
    enum SendError: Error {
        case blocked
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientBalance(balance: Decimal)
        case noTrustline
    }
}
