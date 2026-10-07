import Foundation
import MarketKit
import Testing
@testable import WalletCore

// The NEAR confirmation (Android `SendTransactionServiceNear`): the balance check runs against the
// estimate's required NEAR, which is well above the fee, so the caution names the amount to hold;
// a token's receiver registration is its own row; a pending send only warns.
struct NearSendDataTests {
    @Test func insufficientNearCautionNamesTheRequiredAmount() throws {
        let required = Decimal(string: "0.0313")!
        let data = Self.sendData(transactionError: NearSendHelper.TransactionError.insufficientNearBalance(required: required))

        let caution = try #require(data.cautions(baseToken: Self.nearToken, currency: Self.currency, rates: [:]).first)
        let requiredString = AppValue(token: Self.nearToken, value: required).formattedFull() ?? ""

        #expect(caution.title == "fee_settings.errors.insufficient_balance".localized)
        #expect(caution.text == "transaction.error.insufficient_balance".localized(requiredString))
        #expect(caution.text.contains(requiredString))
        #expect(caution.type == .error)
        #expect(!data.canSend)
    }

    @Test func requiredNearAboveAvailableIsInsufficient() {
        let estimate = Self.estimate(requiredNear: Decimal(string: "1.0153")!)

        let error = NearSendHelper.transactionError(token: Self.nearToken, amount: 1, tokenBalance: 0, availableNear: Decimal(string: "1.01")!, estimate: estimate)

        guard case let .insufficientNearBalance(required) = error as? NearSendHelper.TransactionError else {
            Issue.record("expected an insufficient NEAR error, got \(String(describing: error))")
            return
        }
        #expect(required == Decimal(string: "1.0153")!)
    }

    // a token transfer on an account holding no NEAR: the token is there, the gas is not
    @Test func tokenSendWithoutNearIsInsufficientNear() {
        let estimate = Self.estimate(requiredNear: Decimal(string: "0.0313")!, storageDeposit: Decimal(string: "0.00125")!)

        let error = NearSendHelper.transactionError(token: Self.usdtToken, amount: 10, tokenBalance: 100, availableNear: 0, estimate: estimate)

        guard case .insufficientNearBalance = error as? NearSendHelper.TransactionError else {
            Issue.record("expected an insufficient NEAR error, got \(String(describing: error))")
            return
        }
    }

    @Test func tokenAmountAboveBalanceIsInsufficientToken() {
        let error = NearSendHelper.transactionError(token: Self.usdtToken, amount: 101, tokenBalance: 100, availableNear: 1, estimate: Self.estimate(requiredNear: 0.01))

        guard case .insufficientTokenBalance = error as? NearSendHelper.TransactionError else {
            Issue.record("expected an insufficient token error, got \(String(describing: error))")
            return
        }
    }

    @Test func coveredSendHasNoError() {
        #expect(NearSendHelper.transactionError(token: Self.nearToken, amount: 1, tokenBalance: 0, availableNear: 2, estimate: Self.estimate(requiredNear: Decimal(string: "1.0153")!)) == nil)
    }

    @Test func storageDepositShowsAsReceiverRegistrationRow() throws {
        let data = Self.sendData(token: Self.usdtToken, estimate: Self.estimate(requiredNear: 0.03, storageDeposit: Decimal(string: "0.00125")!))

        let fields = data.feeFields(baseToken: Self.nearToken, currency: Self.currency, rates: [:])

        #expect(fields.count == 2)
        #expect(fields.first?.content is FeeField)
        let registration = try #require(fields.last?.content as? ValueField)
        #expect(registration.appValue?.value == Decimal(string: "0.00125")!)
        #expect(registration.formatFull)
    }

    @Test func noStorageDepositShowsOnlyTheFee() {
        let data = Self.sendData(estimate: Self.estimate(requiredNear: 0.01))

        let fields = data.feeFields(baseToken: Self.nearToken, currency: Self.currency, rates: [:])

        #expect(fields.count == 1)
        #expect(fields.first?.content is FeeField)
    }

    @Test func storageDepositTooHighIsAnError() throws {
        let data = Self.sendData(transactionError: NearSendHelper.TransactionError.storageDepositTooHigh)

        let caution = try #require(data.cautions(baseToken: Self.nearToken, currency: Self.currency, rates: [:]).first)

        #expect(caution.text == "send.near.storage_deposit_too_high".localized)
        #expect(caution.type == .error)
        #expect(!data.canSend)
    }

    // as Android: a warning, never a block
    @Test func previousPendingTransactionWarnsWithoutBlocking() {
        let data = Self.sendData(previousTransactionPending: true)

        let cautions = data.cautions(baseToken: Self.nearToken, currency: Self.currency, rates: [:])

        #expect(cautions.count == 1)
        #expect(cautions.first?.type == .warning)
        #expect(cautions.first?.text == "send.near.previous_transaction_pending".localized)
        #expect(data.canSend)
    }

    // the estimate is what the send passes on: without one there is nothing confirmed to send
    @Test func missingEstimateBlocksTheSend() {
        #expect(!Self.sendData(estimate: nil).canSend)
    }

    @Test func memoIsShownOnTheConfirmation() throws {
        let data = Self.sendData(token: Self.usdtToken, memo: "order-42")

        let fields = data.fields(baseToken: Self.nearToken, currency: Self.currency, rates: [:])

        #expect(fields.count == 1)
    }

    @Test func rejectionForBalanceReadsAsInsufficientBalance() {
        #expect(NearSendHelper.rejectedError(details: #"{"TxExecutionError":{"InvalidTxError":{"NotEnoughBalance":{}}}}"#) == .insufficientBalance)
        #expect(NearSendHelper.rejectedError(details: #"{"InvalidTxError":{"LackBalanceForState":{}}}"#) == .insufficientBalance)
        #expect(NearSendHelper.rejectedError(details: #"{"InvalidTxError":"Expired"}"#) == .rejected)
    }
}

extension NearSendDataTests {
    static let currency = Currency(code: "USD", symbol: "$", decimal: 2)

    static let nearToken = Token(
        coin: Coin(uid: "near", name: "NEAR Protocol", code: "NEAR"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .native,
        decimals: 24
    )

    static let usdtToken = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        type: .nep141(contractId: "usdt.tether-token.near"),
        decimals: 6
    )

    static func estimate(requiredNear: Decimal, storageDeposit: Decimal? = nil) -> NearSendEstimate {
        NearSendEstimate(fee: Decimal(string: "0.0000446")!, storageDeposit: storageDeposit, requiredNear: requiredNear, ftTransferEstimate: nil)
    }

    static func sendData(
        token: Token = NearSendDataTests.nearToken,
        memo: String? = nil,
        estimate: NearSendEstimate? = NearSendDataTests.estimate(requiredNear: 0.01),
        transactionError: Error? = nil,
        previousTransactionPending: Bool = false
    ) -> NearSendHandler.SendData {
        NearSendHandler.SendData(
            token: token,
            amount: 1,
            address: "alice.near",
            memo: memo,
            estimate: estimate,
            fee: estimate?.fee ?? Decimal(string: "0.0000446")!,
            transactionError: transactionError,
            previousTransactionPending: previousTransactionPending
        )
    }
}
