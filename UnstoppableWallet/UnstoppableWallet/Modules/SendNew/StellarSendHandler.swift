import Foundation
import MarketKit
import StellarKit
import stellarsdk

class StellarSendHandler {
    private let stellarKit: StellarKit.Kit
    private let keyPair: KeyPair
    private let token: Token
    let baseToken: Token
    private let data: StellarSendData
    private let memo: String?

    init(stellarKit: StellarKit.Kit, keyPair: KeyPair, token: Token, baseToken: Token, data: StellarSendData, memo: String?) {
        self.stellarKit = stellarKit
        self.keyPair = keyPair
        self.token = token
        self.baseToken = baseToken
        self.data = data
        self.memo = memo
    }
}

extension StellarSendHandler: ISendHandler {
    var expirationDuration: Int? {
        nil
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        var fee: Decimal?
        var transactionError: Error?
        var operations: [stellarsdk.Operation]?
        let stellarBalance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0

        var data = data

        do {
            switch data {
            case let .payment(asset, amount, accountId):
                let result = try await StellarSendHelper.preparePayment(
                    asset: asset,
                    amount: amount,
                    adjustNativeBalance: true,
                    accountId: accountId,
                    stellarKit: stellarKit
                )
                operations = result.operations
                fee = result.fee
                
                if result.adjustedAmount != amount {
                    data = .payment(asset: asset, amount: result.adjustedAmount, accountId: accountId)
                }
            case let .changeTrust(asset, limit):
                let baseFee = try await stellarKit.baseFee()
                let stellarBalance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0

                guard stellarBalance >= baseFee else {
                    throw StellarSendHelper.TransactionError.insufficientStellarBalance(balance: stellarBalance)
                }

                let operation = try stellarKit.changeTrustOperation(asset: asset, limit: limit)
                operations = [operation]
                fee = baseFee
            }
        } catch {
            transactionError = error
        }

        return SendData(
            token: token,
            data: data,
            memo: memo,
            fee: fee,
            transactionError: transactionError,
            operations: operations
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData, let operations = data.operations else {
            throw StellarSendHelper.SendError.noStellarKit
        }

        let memo = data.memo.map { Memo.text($0) } ?? Memo.none

        _ = try await StellarSendHelper.send(
            operations: operations,
            memo: memo,
            keyPair: keyPair
        )
    }
}

extension StellarSendHandler {
    class SendData: ISendData {
        private let token: Token
        private let data: StellarSendData
        let memo: String?
        private let fee: Decimal?
        private let transactionError: Error?
        let operations: [stellarsdk.Operation]?

        init(token: Token, data: StellarSendData, memo: String?, fee: Decimal?, transactionError: Error?, operations: [stellarsdk.Operation]?) {
            self.token = token
            self.data = data
            self.memo = memo
            self.fee = fee
            self.transactionError = transactionError
            self.operations = operations
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
            guard let transactionError else {
                return []
            }

            return [StellarSendHelper.caution(transactionError: transactionError, feeToken: baseToken)]
        }

        func flowSection(baseToken _: Token, currency: Currency, rates: [String: Decimal]) -> SendDataSection {
            switch data {
            case let .payment(_, amount, accountId):
                return .init([
                    .amountNew(
                        token: token,
                        appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                        currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) }
                    ),
                    .address(
                        value: accountId,
                        blockchainType: .stellar
                    ),
                ], isFlow: true)
            case let .changeTrust(asset, limit):
                let appValue = AppValue(token: token, value: limit)
                return .init([
                    .amountNew(
                        token: token,
                        appValueType: appValue.isMaxValue ? .infinity(code: appValue.code) : .regular(appValue: appValue),
                        currencyValue: appValue.isMaxValue ? nil : rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * limit) },
                    ),
                    .address(
                        value: asset.issuer ?? "",
                        blockchainType: .stellar
                    ),
                ], isFlow: true)
            }
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            return [
                flowSection(baseToken: baseToken, currency: currency, rates: rates),
                .init(fields + StellarSendHelper.feeFields(
                    fee: fee,
                    feeToken: baseToken,
                    currency: currency,
                    feeTokenRate: rates[token.coin.uid]
                ), isMain: false),
            ]
        }
    }
}

extension StellarSendHandler {
    enum SendError: Error {
        case invalidAmount
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientStellarBalance(balance: Decimal)
        case noTrustline
    }
}

extension StellarSendHandler {
    static func instance(data: StellarSendData, token: Token, memo: String?) -> StellarSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native)) else {
            return nil
        }

        guard let stellarKit = Core.shared.stellarKitManager.stellarKit else {
            return nil
        }

        guard let account = Core.shared.accountManager.activeAccount, let keyPair = try? StellarKitManager.keyPair(accountType: account.type) else {
            return nil
        }

        return StellarSendHandler(
            stellarKit: stellarKit,
            keyPair: keyPair,
            token: token,
            baseToken: baseToken,
            data: data,
            memo: memo
        )
    }
}
