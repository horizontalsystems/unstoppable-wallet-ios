import AnyCodable
import Foundation
import MarketKit
import StellarKit
import stellarsdk

class WalletConnectStellarSendHandler {
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

extension WalletConnectStellarSendHandler: ISendHandler {
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
        var fee: Decimal?
        var transactionError: Error?

        guard let transaction = try? stellarKit.transaction(transactionEnvelope: payload.xdr) else {
            throw SendError.invalidData
        }

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
    }

    func send(data: ISendData) async throws {
        guard let data = data as? StellarSendData else {
            throw SendError.invalidData
        }

        let _ = try await StellarKit.Kit.send(transactionEnvelope: data.xdr, keyPair: keyPair)

        let responseDict = ["status": "success"]
        signService.approveRequest(id: request.id, result: responseDict)

        DispatchQueue.main.async {
            HudHelper.instance.show(banner: .sent)
        }
    }
}

extension WalletConnectStellarSendHandler {
    class StellarSendData: ISendData {
        private let token: Token
        let xdr: String
        private let transaction: Transaction
        private let dAppName: String
        private let chain: WalletConnectRequest.Chain

        private let fee: Decimal?
        private let transactionError: Error?

        init(token: Token, xdr: String, transaction: Transaction, dAppName: String, chain: WalletConnectRequest.Chain, fee: Decimal?, transactionError: Error?) {
            self.token = token
            self.xdr = xdr
            self.transaction = transaction
            self.dAppName = dAppName
            self.chain = chain
            self.fee = fee
            self.transactionError = transactionError
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

extension WalletConnectStellarSendHandler {
    static func instance(request: WalletConnectRequest) -> WalletConnectStellarSendHandler? {
        guard let payload = request.payload as? WCSendStellarTransactionPayload,
              let account = Core.shared.accountManager.activeAccount,
              let stellarKit = Core.shared.stellarKitManager.stellarKit,
              let keyPair = try? StellarKitManager.keyPair(accountType: account.type)
        else {
            return nil
        }

        guard let baseToken = try? Core.shared.coinManager.token(query: .init(blockchainType: .stellar, tokenType: .native)) else {
            return nil
        }

        return WalletConnectStellarSendHandler(
            request: request,
            payload: payload,
            baseToken: baseToken,
            keyPair: keyPair,
            stellarKit: stellarKit,
        )
    }
}
