import AnyCodable
import Foundation
import MarketKit
import StellarKit
import stellarsdk

class WalletConnectStellarTransactionHandler {
    private let request: WalletConnectRequest
    private let payload: WCStellarTransactionPayload
    private let signService: IWalletConnectSignService = Core.shared.walletConnectSessionManager.service

    let baseToken: Token
    private let stellarKit: StellarKit.Kit
    private let keyPair: KeyPair

    init(request: WalletConnectRequest, payload: WCStellarTransactionPayload, baseToken: Token, keyPair: KeyPair, stellarKit: StellarKit.Kit) {
        self.request = request
        self.payload = payload
        self.baseToken = baseToken
        self.keyPair = keyPair
        self.stellarKit = stellarKit
    }
}

extension WalletConnectStellarTransactionHandler: ISendHandler {
    var syncingText: String? {
        nil
    }

    var expirationDuration: Int? {
        nil
    }

    var initialTransactionSettings: InitialTransactionSettings? {
        nil
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        guard let transaction = try? stellarKit.transaction(transactionEnvelope: payload.xdr) else {
            throw SendError.invalidData
        }

        switch payload {
        case is WCSignStellarTransactionPayload:
            return StellarSignData(
                xdr: payload.xdr,
                transaction: transaction,
                dAppName: payload.dAppName,
                chain: request.chain
            )
        case is WCSendStellarTransactionPayload:
            var fee: Decimal?
            var transactionError: Error?

            let stellarBalance = stellarKit.account?.assetBalanceMap[.native]?.balance ?? 0

            do {
                let estimated = Decimal(transaction.fee) / pow(10, baseToken.decimals)

                fee = estimated

                if stellarBalance < estimated {
                    throw TransactionError.insufficientStellarBalance(balance: stellarBalance)
                }
            } catch {
                transactionError = error
            }

            return StellarSendData(
                token: baseToken,
                xdr: payload.xdr,
                transaction: transaction,
                dAppName: payload.dAppName,
                chain: request.chain,
                fee: fee,
                transactionError: transactionError
            )
        default:
            throw SendError.invalidData
        }
    }

    func send(data: ISendData) async throws {
        switch data {
        case let data as StellarSignData:
            let signedXdr = try StellarKit.Kit.sign(transactionEnvelope: data.xdr, keyPair: keyPair)

            let responseDict = ["signedXDR": signedXdr]
            signService.approveRequest(id: request.id, result: responseDict)
        case let data as StellarSendData:
            let _ = try await StellarKit.Kit.send(transactionEnvelope: data.xdr, keyPair: keyPair)

            let responseDict = ["status": "success"]
            signService.approveRequest(id: request.id, result: responseDict)

            DispatchQueue.main.async {
                HudHelper.instance.show(banner: .sent)
            }
        default:
            throw SendError.invalidData
        }
    }
}

extension WalletConnectStellarTransactionHandler {
    class StellarData {
        let xdr: String
        let transaction: Transaction
        let dAppName: String
        let chain: WalletConnectRequest.Chain

        init(xdr: String, transaction: Transaction, dAppName: String, chain: WalletConnectRequest.Chain) {
            self.xdr = xdr
            self.transaction = transaction
            self.dAppName = dAppName
            self.chain = chain
        }

        var sections: [SendDataSection] {
            var sections = [SendDataSection]()

            var transactionFields = [SendField]()
            let operations = transaction.operations.map { String(describing: type(of: $0)) }
            transactionFields.append(contentsOf: operations.map {
                .simpleValue(title: "send.confirmation.operation".localized, value: $0, copying: false)
            })

            transactionFields.append(.simpleValue(title: "send.confirmation.transaction_xdr".localized, value: xdr.shortened, copying: true))

            sections.append(.init(transactionFields))

            var chainFields = [SendField]()
            chainFields.append(.simpleValue(title: "wallet_connect.sign.dapp_name".localized, value: dAppName, copying: false))

            if let chainName = chain.chainName?.capitalized {
                chainFields.append(.simpleValue(title: chainName, value: chain.address?.shortened ?? "", copying: false))
            }

            sections.append(.init(chainFields))

            return sections
        }
    }

    class StellarSignData: StellarData, ISendData {
        override init(xdr: String, transaction: Transaction, dAppName: String, chain: WalletConnectRequest.Chain) {
            super.init(xdr: xdr, transaction: transaction, dAppName: dAppName, chain: chain)
        }

        var feeData: FeeData? { nil }

        var canSend: Bool {
            true
        }

        var rateCoins: [Coin] {
            []
        }

        var customSendButtonTitle: String? { "button.sign".localized }

        func cautions(baseToken _: Token) -> [CautionNew] {
            []
        }

        func sections(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendDataSection] {
            super.sections
        }
    }

    class StellarSendData: StellarData, ISendData {
        private let token: Token
        private let fee: Decimal?
        private let transactionError: Error?

        init(token: Token, xdr: String, transaction: Transaction, dAppName: String, chain: WalletConnectRequest.Chain, fee: Decimal?, transactionError: Error?) {
            self.token = token
            self.fee = fee
            self.transactionError = transactionError

            super.init(xdr: xdr, transaction: transaction, dAppName: dAppName, chain: chain)
        }

        var feeData: FeeData? { nil }

        var canSend: Bool {
            transactionError != nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        var customSendButtonTitle: String? { "button.send".localized }

        private func caution(transactionError: Error, feeToken: Token) -> CautionNew {
            let title: String
            let text: String

            if let stellarError = transactionError as? TransactionError {
                switch stellarError {
                case let .insufficientStellarBalance(balance):
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

        func cautions(baseToken: Token) -> [CautionNew] {
            transactionError.map { [caution(transactionError: $0, feeToken: baseToken)] } ?? []
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            var sections = super.sections

            if let fee {
                let feeSection = SendDataSection([
                    .value(
                        title: "send.max_fee".localized,
                        description: .init(title: "send.max_fee".localized, description: "fee_settings.network_fee.info".localized),
                        appValue: AppValue(token: baseToken, value: fee),
                        currencyValue: rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) },
                        formatFull: true
                    ),
                ])
                sections.append(feeSection)
            }

            return sections
        }
    }

    enum SendError: Error {
        case invalidData
    }

    enum TransactionError: Error {
        case insufficientStellarBalance(balance: Decimal)
    }
}

extension WalletConnectStellarTransactionHandler {
    static func instance(request: WalletConnectRequest) -> WalletConnectStellarTransactionHandler? {
        guard let payload = request.payload as? WCStellarTransactionPayload,
              let account = Core.shared.accountManager.activeAccount,
              let stellarKit = try? Core.shared.stellarKitManager.stellarKit(account: account),
              let keyPair = try? StellarKitManager.keyPair(accountType: account.type)
        else {
            return nil
        }

        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native)) else {
            return nil
        }

        return WalletConnectStellarTransactionHandler(
            request: request,
            payload: payload,
            baseToken: baseToken,
            keyPair: keyPair,
            stellarKit: stellarKit,
        )
    }
}
