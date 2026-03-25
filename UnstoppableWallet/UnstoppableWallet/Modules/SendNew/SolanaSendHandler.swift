import Foundation
import MarketKit
import SolanaKit

class SolanaSendHandler {
    private let solanaKit: SolanaKit.Kit
    private let signer: SolanaKit.Signer
    private let token: Token
    let baseToken: Token
    private let adapter: ISendSolanaAdapter & IBalanceAdapter
    private let amount: Decimal
    private let address: String
    private let memo: String?

    init(solanaKit: SolanaKit.Kit, signer: SolanaKit.Signer, token: Token, baseToken: Token, adapter: ISendSolanaAdapter & IBalanceAdapter, amount: Decimal, address: String, memo: String?) {
        self.solanaKit = solanaKit
        self.signer = signer
        self.token = token
        self.baseToken = baseToken
        self.adapter = adapter
        self.amount = amount
        self.address = address
        self.memo = memo
    }
}

extension SolanaSendHandler: ISendHandler {
    var expirationDuration: Int? {
        10
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let fee = adapter.fee
        var transactionError: Error?
        var finalAmount = amount

        let solBalance = solanaKit.balance

        if token.type.isNative {
            if amount == solBalance {
                // Send max: subtract fee
                finalAmount = max(0, solBalance - fee)
                if finalAmount == 0 {
                    transactionError = TransactionError.insufficientSolBalance(balance: solBalance)
                }
            } else if amount + fee > solBalance {
                transactionError = TransactionError.insufficientSolBalance(balance: solBalance)
            }
        } else {
            // SPL token: need SOL balance to cover fee
            if solBalance < fee {
                transactionError = TransactionError.insufficientSolBalance(balance: solBalance)
            }
        }

        return SendData(
            token: token,
            amount: finalAmount,
            address: address,
            memo: memo,
            fee: fee,
            transactionError: transactionError
        )
    }

    func send(data: ISendData) async throws {
        guard let data = data as? SendData else {
            throw SendError.invalidData
        }

        if token.type.isNative {
            try await adapter.sendSol(toAddress: data.address, amount: data.amount, signer: signer)
        } else {
            guard case let .spl(mintAddress) = token.type else {
                throw SendError.invalidData
            }
            try await adapter.sendSpl(
                mintAddress: mintAddress,
                toAddress: data.address,
                amount: data.amount,
                decimals: token.decimals,
                signer: signer
            )
        }
    }
}

extension SolanaSendHandler {
    class SendData: ISendData {
        let token: Token
        let amount: Decimal
        let address: String
        let memo: String?
        private let fee: Decimal
        private let transactionError: Error?

        init(token: Token, amount: Decimal, address: String, memo: String?, fee: Decimal, transactionError: Error?) {
            self.token = token
            self.amount = amount
            self.address = address
            self.memo = memo
            self.fee = fee
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

        private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let solanaError = transactionError as? SolanaSendHandler.TransactionError {
                switch solanaError {
                case let .insufficientSolBalance(balance):
                    let appValue = AppValue(token: feeToken, value: balance)
                    let balanceString = appValue.formattedShort()

                    title = "fee_settings.errors.insufficient_balance".localized
                    text = "fee_settings.errors.insufficient_balance.info".localized(balanceString ?? "")
                }
            } else {
                title = "ethereum_transaction.error.title".localized
                text = transactionError.convertedError.smartDescription
            }

            return CautionNew(title: title, text: text, type: .error)
        }

        func cautions(baseToken: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            var cautions = [CautionNew]()

            if let transactionError {
                cautions.append(caution(transactionError: transactionError, feeToken: baseToken))
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
                    blockchainType: .solana
                ),
            ], isFlow: true)
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var fields = [SendField]()

            if let memo {
                fields.append(.simpleValue(title: "send.confirmation.memo".localized, value: memo))
            }

            return [
                flowSection(baseToken: baseToken, currency: currency, rates: rates),
                .init(fields + feeFields(currency: currency, feeToken: baseToken, feeTokenRate: rates[baseToken.coin.uid]), isMain: false),
            ]
        }

        private func feeFields(currency: Currency, feeToken: Token, feeTokenRate: Decimal?) -> [SendField] {
            let appValue = AppValue(token: feeToken, value: fee)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: fee * $0) }

            return [
                .fee(
                    title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                    amountData: .init(appValue: appValue, currencyValue: currencyValue)
                ),
            ]
        }
    }
}

extension SolanaSendHandler {
    enum SendError: Error {
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientSolBalance(balance: Decimal)
    }
}

extension SolanaSendHandler {
    static func instance(token: Token, amount: Decimal, address: String, memo: String?) -> SolanaSendHandler? {
        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .solana, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ISendSolanaAdapter & IBalanceAdapter else {
            return nil
        }

        guard let solanaKit = Core.shared.solanaKitManager.solanaKit else {
            return nil
        }

        guard let account = Core.shared.accountManager.activeAccount,
              let signer = try? SolanaKitManager.signer(accountType: account.type)
        else {
            return nil
        }

        return SolanaSendHandler(
            solanaKit: solanaKit,
            signer: signer,
            token: token,
            baseToken: baseToken,
            adapter: adapter,
            amount: amount,
            address: address,
            memo: memo
        )
    }
}
