import Foundation
import MarketKit
import StellarKit
import Testing
@testable import WalletCore

// Android send v2 parity on the confirmation: a refusal that needs new input shows a disabled
// Send (a custom button title); every other error leaves the title empty, so Refresh stays.
struct StellarXrpSendButtonTests {
    @Test func stellarBelowMinimumFirstDepositDisablesSend() {
        #expect(stellarTitle(StellarSendHelper.TransactionError.belowMinimumFirstDeposit(minimum: 1)) == "button.send".localized)
    }

    @Test func stellarRefreshableErrorsKeepRefresh() {
        #expect(stellarTitle(StellarSendHelper.TransactionError.insufficientStellarBalance(balance: 1)) == nil)
        #expect(stellarTitle(StellarSendHelper.TransactionError.noTrustline) == nil)
        #expect(stellarTitle(StubError.network) == nil)
        #expect(stellarTitle(nil) == nil)
    }

    @Test func xrpInputRefusalsDisableSend() {
        #expect(xrpTitle(XrpSendHelper.TransactionError.belowMinimumFirstDeposit(minimum: 1)) == "button.send".localized)
        #expect(xrpTitle(XrpSendHelper.TransactionError.destinationRequiresTag) == "button.send".localized)
    }

    @Test func xrpRefreshableErrorsKeepRefresh() {
        #expect(xrpTitle(XrpSendHelper.TransactionError.insufficientXrpBalance(balance: 1)) == nil)
        #expect(xrpTitle(XrpSendHelper.TransactionError.insufficientTokenBalance) == nil)
        #expect(xrpTitle(XrpSendHelper.TransactionError.insufficientActivationBalance) == nil)
        #expect(xrpTitle(StubError.network) == nil)
        #expect(xrpTitle(nil) == nil)
    }
}

extension StellarXrpSendButtonTests {
    private func stellarTitle(_ error: Error?) -> String? {
        StellarSendHandler.SendData(
            token: Self.xlmToken,
            data: .payment(asset: .native, amount: 1, accountId: "GDESTINATION"),
            memo: nil,
            fee: 0.0001,
            transactionError: error,
            operations: nil
        ).customSendButtonTitle
    }

    private func xrpTitle(_ error: Error?) -> String? {
        XrpSendHandler.SendData(
            token: Self.xrpToken,
            data: .payment(amount: 1, address: "rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh"),
            destinationTag: nil,
            fee: 0.00001,
            ownerReserve: 0.2,
            transactionError: error
        ).customSendButtonTitle
    }

    private static let xlmToken = Token(
        coin: Coin(uid: "stellar", name: "Stellar", code: "XLM"),
        blockchain: Blockchain(type: .stellar, name: "Stellar", explorerUrl: nil),
        type: .native,
        decimals: 7
    )

    private static let xrpToken = Token(
        coin: Coin(uid: "ripple", name: "XRP", code: "XRP"),
        blockchain: Blockchain(type: .xrp, name: "XRP Ledger", explorerUrl: nil),
        type: .native,
        decimals: 6
    )

    enum StubError: Error {
        case network
    }
}
