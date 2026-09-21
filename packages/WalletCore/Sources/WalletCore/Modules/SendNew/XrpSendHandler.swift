import Foundation
import MarketKit
import XrpKit

class XrpSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .xrp(token, data, destinationTag) = sendData else { return nil }
        return instance(token: token, data: data, destinationTag: destinationTag)
    }

    private let signer: XrpKit.Signer
    private let token: Token
    let baseToken: Token
    private let adapter: ISendXrpAdapter & IBalanceAdapter
    private let data: XrpSendData
    private let destinationTag: UInt32?

    init(signer: XrpKit.Signer, token: Token, baseToken: Token, adapter: ISendXrpAdapter & IBalanceAdapter, data: XrpSendData, destinationTag: UInt32?) {
        self.signer = signer
        self.token = token
        self.baseToken = baseToken
        self.adapter = adapter
        self.data = data
        self.destinationTag = destinationTag
    }
}

extension XrpSendHandler: ISendHandler {
    var expirationDuration: Int? {
        nil
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let fee = adapter.fee
        var transactionError: Error?

        // the fee is always paid in XRP on top of the amount; spendable XRP already excludes the reserve
        let availableXrp = adapter.availableXrpBalance
        switch data {
        case let .payment(amount, address):
            if token.type.isNative {
                if amount + fee > availableXrp {
                    transactionError = XrpSendHelper.TransactionError.insufficientXrpBalance(balance: availableXrp)
                }
            } else if amount > adapter.balanceData.available {
                transactionError = XrpSendHelper.TransactionError.insufficientTokenBalance
            } else if fee > availableXrp {
                transactionError = XrpSendHelper.TransactionError.insufficientXrpBalance(balance: availableXrp)
            }

            if transactionError == nil {
                transactionError = await XrpSendHelper.destinationError(
                    adapter: adapter, token: token, amount: amount,
                    address: address, destinationTag: destinationTag
                )
            }
        case .trustSet:
            // the new object also locks one owner reserve increment (Android `validateActivation`)
            if fee + adapter.ownerReserve > availableXrp {
                transactionError = XrpSendHelper.TransactionError.insufficientActivationBalance
            }
        }

        return SendData(token: token, data: data, destinationTag: destinationTag, fee: fee, ownerReserve: adapter.ownerReserve, transactionError: transactionError)
    }

    func send(data: ISendData) async throws {
        _ = try await sendCapturingRef(data: data)
    }
}

extension XrpSendHandler: ISendHandlerRefCapturing {
    // Same broadcast path as `send`, returning the on-chain tx hash.
    func sendCapturingRef(data: ISendData) async throws -> String {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        switch data.data {
        case let .payment(amount, address):
            return try await adapter.send(amount: amount, address: address, destinationTag: data.destinationTag, signer: signer)
        case let .trustSet(currency, issuer, limit):
            return try await adapter.setTrustLine(currency: currency, issuer: issuer, limit: limit, signer: signer)
        }
    }
}

extension XrpSendHandler {
    class SendData: ISendData {
        let token: Token
        let data: XrpSendData
        let destinationTag: UInt32?
        private let fee: Decimal
        private let ownerReserve: Decimal
        private let transactionError: Error?

        init(token: Token, data: XrpSendData, destinationTag: UInt32?, fee: Decimal, ownerReserve: Decimal, transactionError: Error?) {
            self.token = token
            self.data = data
            self.destinationTag = destinationTag
            self.fee = fee
            self.ownerReserve = ownerReserve
            self.transactionError = transactionError
        }

        var feeData: FeeData? {
            nil
        }

        var canSend: Bool {
            transactionError == nil
        }

        var customSendButtonTitle: String? {
            nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(XrpSendHelper.caution(transactionError: transactionError, feeToken: baseToken))
            }

            // the reserve note of the Android activation page: locked, not spent
            if case .trustSet = data {
                let reserve = AppValue(token: baseToken, value: ownerReserve).formattedFull() ?? ""
                cautions.append(CautionNew(text: "send.xrp.activation.reserve_note".localized(reserve), type: .regular))
            }

            return cautions
        }

        func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            switch data {
            case let .payment(amount, address):
                return .init([
                    .amount(
                        token: token,
                        appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                        currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) }
                    ),
                    .address(
                        value: address,
                        blockchainType: .xrp
                    ),
                ], isFlow: true)
            case let .trustSet(_, issuer, limit):
                let appValue = AppValue(token: token, value: limit)
                return .init([
                    .amount(
                        token: token,
                        appValueType: limit == XrpKit.Kit.defaultTrustLimit ? .infinity(code: appValue.code) : .regular(appValue: appValue),
                        currencyValue: nil
                    ),
                    .address(
                        value: issuer,
                        blockchainType: .xrp
                    ),
                ], isFlow: true)
            }
        }

        func fields(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
            var fields = [SendField]()

            if let destinationTag {
                fields.append(.simpleValue(title: "send.xrp.destination_tag".localized, value: String(destinationTag)))
            }

            return fields
        }

        func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
            XrpSendHelper.feeFields(fee: fee, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            let flow = flowSection(baseToken: baseToken, currency: currency, rates: rates)
            let fields = fields(baseToken: baseToken, currency: currency, rates: rates)
            let feeFields = feeFields(baseToken: baseToken, currency: currency, rates: rates)

            return [flow, .init(fields + feeFields, isMain: false)]
        }
    }
}

extension XrpSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension XrpSendHandler {
    static func instance(token: Token, data: XrpSendData, destinationTag: UInt32?) -> XrpSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .xrp, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ISendXrpAdapter & IBalanceAdapter else {
            return nil
        }

        guard let account = Core.shared.accountManager.activeAccount,
              let signer = try? XrpKitManager.signer(accountType: account.type)
        else {
            return nil
        }

        return XrpSendHandler(signer: signer, token: token, baseToken: baseToken, adapter: adapter, data: data, destinationTag: destinationTag)
    }
}
