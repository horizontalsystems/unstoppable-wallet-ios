import Foundation
import MarketKit

class MigrationSendHandler: SendHandler {
    override class func instance(sendData: WalletCore.SendData) -> ISendHandler? {
        guard case .zcashMigration = sendData else { return nil }
        return instance()
    }

    private let token: Token
    private let adapter: ZcashAdapter

    init(token: Token, adapter: ZcashAdapter) {
        self.token = token
        self.adapter = adapter
    }
}

extension MigrationSendHandler: ISendHandler {
    var baseToken: Token {
        token
    }

    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData {
        let proposal = try await adapter.migrationProposal()
        return SendData(token: token, amount: proposal.amount, fee: proposal.fee)
    }

    func send(data _: ISendData) async throws {
        _ = try await adapter.performMigration()
    }
}

extension MigrationSendHandler {
    class SendData: ISendData {
        private let token: Token
        let amount: Decimal
        let fee: Decimal
        var transactionError: Error?

        init(token: Token, amount: Decimal, fee: Decimal) {
            self.token = token
            self.amount = amount
            self.fee = fee
        }

        var feeData: FeeData? {
            .zcash(fee: fee)
        }

        var canSend: Bool {
            transactionError == nil
        }

        var rateCoins: [Coin] {
            [token.coin]
        }

        func cautions(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [CautionNew] {
            [CautionNew(
                title: "zcash.migration.warning.title".localized,
                text: "zcash.migration.warning".localized,
                type: .warning
            )]
        }

        func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection] {
            let flowFields: [SendField] = [
                .amount(
                    token: token,
                    appValueType: .regular(appValue: AppValue(token: token, value: amount)),
                    currencyValue: rates[token.coin.uid].map { CurrencyValue(currency: currency, value: $0 * amount) },
                ),
            ]

            let appValue = AppValue(token: baseToken, value: fee)
            let currencyValue = rates[baseToken.coin.uid].map { CurrencyValue(currency: currency, value: fee * $0) }

            return [
                .init(flowFields, isFlow: true),
                .init([
                    .fee(
                        title: ComponentInformedTitle("fee_settings.network_fee".localized, info: .fee),
                        amountData: .init(appValue: appValue, currencyValue: currencyValue)
                    ),
                ], isMain: false),
            ]
        }
    }
}

extension MigrationSendHandler {
    static func instance() -> MigrationSendHandler? {
        guard let token = try? Core.shared.coinManager.token(query: .init(blockchainType: .zcash, tokenType: .native)) else {
            return nil
        }

        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter else {
            return nil
        }

        return MigrationSendHandler(token: token, adapter: adapter)
    }
}
