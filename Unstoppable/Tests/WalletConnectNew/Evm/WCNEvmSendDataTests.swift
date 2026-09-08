import EvmKit
import Foundation
import MarketKit
import Testing
@testable import WalletCore

struct WCNEvmSendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
    private let token = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .binanceSmartChain, name: "BNB Smart Chain", explorerUrl: nil),
        type: .eip20(address: "0x55d398326f99059ff775485246999027b3197955"),
        decimals: 18
    )

    private func data(type: EvmDecoration.`Type`, nonce: Int? = nil) -> WCNEvmSendData {
        let evmSendData = EvmSendData(
            decoration: EvmDecoration(type: type, customSendButtonTitle: "slide"),
            transactionData: nil, transactionError: nil, gasPrice: nil, evmFeeData: nil, nonce: nonce
        )
        return WCNEvmSendData(evmSendData: evmSendData)
    }

    private func spender() throws -> EvmKit.Address {
        try EvmKit.Address(hex: "0x000000000022d473030f116ddee9f6b43ac78ba3")
    }

    @Test func approveShowsAllowanceAmountAndSpenderWithApproveButton() throws {
        let data = try data(type: .approveEip20(spender: spender(), value: 10, token: token))
        let sections = data.sections(baseToken: token, currency: currency, rates: [:])

        #expect(data.customSendButtonTitle == "swap.approve".localized)
        #expect(sections.count == 1)
        #expect(sections[0].fields.count == 2)
    }

    @Test func transferKeepsDecorationRowsWithoutFee() throws {
        let to = try spender()
        let data = data(type: .outgoingEvm(to: to, value: 1), nonce: 7)
        let sections = data.sections(baseToken: token, currency: currency, rates: [:])
        let decoration = EvmDecoration(type: .outgoingEvm(to: to, value: 1), customSendButtonTitle: nil)
        let expected = (decoration.flowSection(baseToken: token, currency: currency, rates: [:])?.fields.count ?? 0)
            + decoration.fields(baseToken: token, currency: currency, rates: [:]).count + 1

        #expect(data.customSendButtonTitle == nil)
        #expect(sections.count == 1)
        #expect(sections[0].fields.count == expected)
    }
}
