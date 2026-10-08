import Foundation
import MarketKit
import NearKit
import RxSwift
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

    // a dropped connection reaches the confirmation as the kit's error and reads as "no internet"
    @Test func estimationWithoutConnectionShowsNoConnection() async {
        let adapter = EstimateFailingAdapter(error: NoEndpointAvailable(underlying: URLError(.notConnectedToInternet)))

        let estimation = await NearSendHelper.estimation(adapter: adapter, token: Self.nearToken, amount: 1, address: "alice.near", memo: nil, tokenBalance: 0)
        let error = estimation.transactionError ?? NoEndpointAvailable(underlying: nil)

        #expect(estimation.estimate == nil)
        #expect(NearSendHelper.caution(transactionError: error, feeToken: Self.nearToken).text == AppError.noConnection.localizedDescription)
    }

    // "Max" sends the whole spendable balance; the confirmation takes out what this receiver
    // needs (Android `SendTransactionServiceNear.maxSendableAmount`)
    @Test func maxSendIsReducedToTheReceiversMaximum() async throws {
        let adapter = MaxSendAdapter()

        let data = try await Self.sendData(handler: Self.handler(adapter: adapter, amount: 1))

        #expect(data.amount == 1 - MaxSendAdapter.reserve)
        #expect(data.canSend)
        #expect(adapter.estimated == [1, 1 - MaxSendAdapter.reserve])
    }

    // with less than the transfer needs, the amount stays and the caution names what is required
    @Test func maxSendBelowTheReserveIsInsufficient() async throws {
        let adapter = MaxSendAdapter(availableNear: Decimal(string: "0.0001")!)

        let data = try await Self.sendData(handler: Self.handler(adapter: adapter, amount: Decimal(string: "0.0001")!))

        #expect(data.amount == Decimal(string: "0.0001")!)
        #expect(!data.canSend)
        #expect(adapter.estimated.count == 1)
    }

    @Test func amountBelowTheMaxIsKept() async throws {
        let adapter = MaxSendAdapter()

        let data = try await Self.sendData(handler: Self.handler(adapter: adapter, amount: Decimal(string: "0.5")!))

        #expect(data.amount == Decimal(string: "0.5")!)
        #expect(adapter.estimated == [Decimal(string: "0.5")!])
    }

    // a token's fee is paid in NEAR, its amount is never adjusted
    @Test func tokenAmountIsKept() async throws {
        let adapter = MaxSendAdapter()

        let data = try await Self.sendData(handler: Self.handler(token: Self.usdtToken, adapter: adapter, amount: 1))

        #expect(data.amount == 1)
        #expect(adapter.estimated.count == 1)
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

    static func handler(token: Token = NearSendDataTests.nearToken, adapter: MaxSendAdapter, amount: Decimal) throws -> NearSendHandler {
        try NearSendHandler(
            signer: NearKit.Signer.instance(seed: Data(repeating: 1, count: 64)),
            token: token,
            baseToken: nearToken,
            adapter: adapter,
            amount: amount,
            address: "alice.near",
            memo: nil
        )
    }

    static func sendData(handler: NearSendHandler) async throws -> NearSendHandler.SendData {
        let data = try await handler.sendData(transactionSettings: nil)
        return try #require(data as? NearSendHandler.SendData)
    }

    /// `availableNear` spendable; a transfer to the receiver needs `reserve` besides the amount (Android formula, named receiver).
    final class MaxSendAdapter: ISendNearAdapter, IBalanceAdapter {
        static let reserve = Decimal(string: "0.000446365125")!

        private let lock = NSLock()
        private var _estimated = [Decimal]()

        var estimated: [Decimal] {
            lock.lock()
            defer { lock.unlock() }
            return _estimated
        }

        let isMainNet = true
        let balanceState: AdapterState = .synced
        let balanceStateUpdatedObservable: Observable<AdapterState> = .never()
        let balanceData = BalanceData(balance: 100)
        let balanceDataUpdatedObservable: Observable<BalanceData> = .never()

        let address = "bob.near"
        let fee = Decimal(string: "0.0000446")!
        let availableNear: Decimal
        let pendingTransactionHashes = Set<String>()

        init(availableNear: Decimal = 1) {
            self.availableNear = availableNear
        }

        func doesAccountExist(address _: String) async throws -> Bool {
            true
        }

        func estimate(address _: String, amount: Decimal, memo _: String?) async throws -> NearSendEstimate {
            lock.lock()
            _estimated.append(amount)
            lock.unlock()

            return NearSendEstimate(fee: fee, storageDeposit: nil, requiredNear: Self.reserve + amount, ftTransferEstimate: nil)
        }

        func send(amount _: Decimal, address _: String, memo _: String?, estimate _: NearSendEstimate, signer _: NearKit.Signer) async throws -> String {
            fatalError("not sent in these tests")
        }
    }

    struct EstimateFailingAdapter: ISendNearAdapter {
        let error: Error

        let address = "alice.near"
        let fee = Decimal(string: "0.0000446")!
        let availableNear: Decimal = 1
        let pendingTransactionHashes = Set<String>()

        func doesAccountExist(address _: String) async throws -> Bool {
            true
        }

        func estimate(address _: String, amount _: Decimal, memo _: String?) async throws -> NearSendEstimate {
            throw error
        }

        func send(amount _: Decimal, address _: String, memo _: String?, estimate _: NearSendEstimate, signer _: NearKit.Signer) async throws -> String {
            fatalError("not sent in these tests")
        }
    }
}
