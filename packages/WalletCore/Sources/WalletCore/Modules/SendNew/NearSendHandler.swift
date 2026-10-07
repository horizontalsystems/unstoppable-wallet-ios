import Foundation
import MarketKit
import NearKit

class NearSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case let .near(token, amount, address, memo) = sendData else { return nil }
        return instance(token: token, amount: amount, address: address, memo: memo)
    }

    private let signer: NearKit.Signer
    private let token: Token
    let baseToken: Token
    private let adapter: ISendNearAdapter & IBalanceAdapter
    private let amount: Decimal
    private let address: String
    private let memo: String?

    init(signer: NearKit.Signer, token: Token, baseToken: Token, adapter: ISendNearAdapter & IBalanceAdapter, amount: Decimal, address: String, memo: String?) {
        self.signer = signer
        self.token = token
        self.baseToken = baseToken
        self.adapter = adapter
        self.amount = amount
        self.address = address
        self.memo = memo
    }
}

extension NearSendHandler: ISendHandler {
    // refreshed on the shared timer: a storage deposit or the receiver's existence can change meanwhile
    var expirationDuration: Int? {
        nil
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let estimation = await NearSendHelper.estimation(
            adapter: adapter, token: token, amount: amount, address: address, memo: memo,
            tokenBalance: adapter.balanceData.available
        )

        return SendData(
            token: token,
            amount: amount,
            address: address,
            memo: memo,
            estimate: estimation.estimate,
            fee: estimation.estimate?.fee ?? adapter.fee,
            transactionError: estimation.transactionError,
            previousTransactionPending: !adapter.pendingTransactionHashes.isEmpty
        )
    }

    func send(data: ISendData) async throws {
        _ = try await sendCapturingRef(data: data)
    }
}

extension NearSendHandler: ISendHandlerRefCapturing {
    // Same broadcast path as `send`, returning the on-chain tx hash. The estimate is the one the
    // confirmation showed, so a token's storage deposit that changed since is refused by the kit.
    func sendCapturingRef(data: ISendData) async throws -> String {
        guard let data = data as? SendData, let estimate = data.estimate else {
            throw SendError.invalidData
        }

        return try await NearSendHelper.send(adapter: adapter, amount: data.amount, address: data.address, memo: data.memo, estimate: estimate, signer: signer)
    }
}

extension NearSendHandler {
    class SendData: ISendData {
        let token: Token
        let amount: Decimal
        let address: String
        let memo: String?
        let estimate: NearSendEstimate?
        private let fee: Decimal
        private let transactionError: Error?
        private let previousTransactionPending: Bool

        init(token: Token, amount: Decimal, address: String, memo: String?, estimate: NearSendEstimate?, fee: Decimal, transactionError: Error?, previousTransactionPending: Bool) {
            self.token = token
            self.amount = amount
            self.address = address
            self.memo = memo
            self.estimate = estimate
            self.fee = fee
            self.transactionError = transactionError
            self.previousTransactionPending = previousTransactionPending
        }

        var feeData: FeeData? {
            nil
        }

        // the pending warning does not block, as on Android
        var canSend: Bool {
            transactionError == nil && estimate != nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(NearSendHelper.caution(transactionError: transactionError, feeToken: baseToken))
            }

            if previousTransactionPending {
                cautions.append(NearSendHelper.pendingCaution())
            }

            return cautions
        }

        func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            .init([
                .amount(
                    token: token,
                    appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) }
                ),
                .address(
                    value: address,
                    blockchainType: .near
                ),
            ], isFlow: true)
        }

        func fields(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            return fields
        }

        func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField] {
            NearSendHelper.feeFields(fee: fee, storageDeposit: estimate?.storageDeposit, feeToken: baseToken, currency: currency, feeTokenRate: rates[baseToken.coin.uid])
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            let flow = flowSection(baseToken: baseToken, currency: currency, rates: rates)
            let fields = fields(baseToken: baseToken, currency: currency, rates: rates)
            let feeFields = feeFields(baseToken: baseToken, currency: currency, rates: rates)

            return [flow, .init(fields + feeFields, isMain: false)]
        }
    }
}

extension NearSendHandler {
    enum SendError: Error {
        case invalidData
    }
}

extension NearSendHandler {
    static func instance(token: Token, amount: Decimal, address: String, memo: String?) -> NearSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .near, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ISendNearAdapter & IBalanceAdapter else {
            return nil
        }

        guard let account = Core.shared.accountManager.activeAccount,
              let signer = try? NearKitManager.signer(accountType: account.type)
        else {
            return nil
        }

        return NearSendHandler(signer: signer, token: token, baseToken: baseToken, adapter: adapter, amount: amount, address: address, memo: memo)
    }
}
