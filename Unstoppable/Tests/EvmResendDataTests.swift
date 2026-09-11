import BigInt
import EvmKit
import Foundation
import MarketKit
import OneInchKit
import Testing
import UniswapKit
@testable import WalletCore

struct EvmResendDataTests {
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
    private let baseToken = Token(
        coin: Coin(uid: "ethereum", name: "Ethereum", code: "ETH"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil), type: .native, decimals: 18
    )
    private let outputToken = Token(
        coin: Coin(uid: "tether", name: "Tether", code: "USDT"),
        blockchain: Blockchain(type: .ethereum, name: "Ethereum", explorerUrl: nil),
        type: .eip20(address: "0x2222222222222222222222222222222222222222"), decimals: 6
    )

    private func address(_ digit: String = "1") throws -> EvmKit.Address {
        try EvmKit.Address(hex: "0x" + String(repeating: digit, count: 40))
    }

    private func uniswap(exactInput: Bool = true) throws -> SwapDecoration {
        try SwapDecoration(
            contractAddress: address(),
            amountIn: exactInput ? .exact(value: 1_000_000_000_000_000_000) : .extremum(value: 1_000_000_000_000_000_000),
            amountOut: exactInput ? .extremum(value: 2_000_000) : .exact(value: 2_000_000),
            tokenIn: .evmCoin, tokenOut: .eip20Coin(address: address("2"), tokenInfo: nil),
            recipient: address("3"), deadline: nil
        )
    }

    private func decodedSwap(_ decoration: TransactionDecoration) -> EvmResendSwapData? {
        EvmResendSwapData(decoration: decoration, baseToken: baseToken) { _ in outputToken }
    }

    private func data(swap: EvmResendSwapData?, type: EvmDecoration.`Type`? = nil) throws -> EvmResendData {
        let transactionData = try TransactionData(to: address(), value: 1_000_000_000_000_000_000, input: Data([0xAB, 0xCD]))
        return EvmResendData(
            decoration: EvmDecoration(type: type ?? .unknown(to: transactionData.to, value: 1, input: transactionData.input, method: "swap"), customSendButtonTitle: "approve"),
            swap: swap, transactionData: transactionData, transactionError: nil, gasPrice: .legacy(gasPrice: 10),
            evmFeeData: EvmFeeData(gasLimit: 54321, surchargedGasLimit: 54321), nonce: 7
        )
    }

    private func sections(_ data: EvmResendData) -> [SendDataSection] {
        data.sections(baseToken: baseToken, currency: currency, rates: ["ethereum": 3000, "tether": 1])
    }

    @Test(arguments: [true, false]) func uniswapKeepsExactAmountSeparateFromLimit(exactInput: Bool) throws {
        let swap = try #require(decodedSwap(uniswap(exactInput: exactInput)))
        let data = try data(swap: swap)
        let sections = sections(data)
        let amount = try #require(sections[0].fields.first?.content as? AmountField)
        let limit = try #require(sections[1].fields[1].content as? ValueField)
        let recipient = try #require(sections[1].fields[0].content as? RecipientField)
        let nonce = try #require(sections[1].fields[2].content as? SimpleValueField)

        #expect(sections.count == 3)
        #expect(sections[0].fields.count == 1) // The transaction contains no output/input estimate.
        #expect(amount.token == (exactInput ? baseToken : outputToken))
        guard case let .regular(appValue) = amount.appValueType else {
            Issue.record("Replacement must display the exact amount from the transaction")
            return
        }
        #expect(appValue.value == (exactInput ? 1 : 2))
        #expect(amount.currencyValue?.value == (exactInput ? 3000 : 2))
        #expect(limit.title.description == (exactInput ? "swap.confirmation.minimum_received" : "swap.confirmation.maximum_sent").localized)
        #expect(limit.appValue?.value == (exactInput ? 2 : 1))
        #expect(recipient.value == (try address("3").eip55))
        #expect(nonce.value.description == "7")
        #expect(data.rateCoins.map(\.uid) == ["ethereum", "tether"])
        #expect(data.transactionData?.input == Data([0xAB, 0xCD]))
        #expect(data.evmFeeData?.surchargedGasLimit == 54321)
        #expect(data.canSend)
    }

    @Test(arguments: [true, false]) func oneInchSwapAndUnoswapKeepNonceBeforeMinimum(unoswap: Bool) throws {
        let decoration: TransactionDecoration
        if unoswap {
            decoration = try OneInchUnoswapDecoration(
                contractAddress: address(), tokenIn: .evmCoin, tokenOut: .eip20Coin(address: address("2"), tokenInfo: nil),
                amountIn: 1_000_000_000_000_000_000, amountOut: .extremum(value: 2_000_000), params: []
            )
        } else {
            decoration = try OneInchSwapDecoration(
                contractAddress: address(), tokenIn: .evmCoin, tokenOut: .eip20Coin(address: address("2"), tokenInfo: nil),
                amountIn: 1_000_000_000_000_000_000, amountOut: .extremum(value: 2_000_000), flags: 0,
                permit: Data(), data: Data(), recipient: nil
            )
        }
        let swap = try #require(decodedSwap(decoration))
        let sections = try sections(data(swap: swap))
        let nonce = try #require(sections[1].fields.first?.content as? SimpleValueField)
        let minimum = try #require(sections[2].fields.first?.content as? ValueField)

        #expect(sections.count == 4)
        #expect(sections[0].fields.count == 1)
        #expect(nonce.value.description == "7")
        #expect(minimum.title.description == "swap.confirmation.minimum_received".localized)
        #expect(minimum.appValue?.value == 2)
    }

    @Test func missingTokenMetadataPreservesContractFallback() throws {
        let swap = try EvmResendSwapData(decoration: uniswap(), baseToken: baseToken) { _ in nil }
        #expect(swap == nil)
        let data = try data(swap: swap)
        let fields = sections(data).flatMap(\.fields).compactMap { $0.content as? SimpleValueField }
        #expect(fields.contains { $0.title.description == "send.confirmation.input".localized && $0.value.description == "abcd" })
        #expect(fields.contains { $0.title.description == "send.confirmation.method".localized && $0.value.description == "swap" })
    }

    @Test func unoswapWithoutOutputTokenDoesNotInventOne() throws {
        let decoration = try OneInchUnoswapDecoration(
            contractAddress: address(), tokenIn: .evmCoin, tokenOut: nil,
            amountIn: 1, amountOut: .extremum(value: 2), params: []
        )
        #expect(decodedSwap(decoration) == nil)
    }

    @Test func approveReusesExistingDecorationAndDoesNotUseApproveButtonTitle() throws {
        let type: EvmDecoration.`Type` = try .approveEip20(spender: address("3"), value: 5, token: outputToken)
        let data = try data(swap: nil, type: type)
        let sections = sections(data)
        let amount = try #require(sections[0].fields.first?.content as? AmountField)
        let spender = try #require(sections[1].fields.first?.content as? RecipientField)
        #expect(amount.token == outputToken)
        #expect(spender.value == (try address("3").eip55))
        #expect(data.rateCoins.map(\.uid) == ["tether"])
        #expect(data.customSendButtonTitle == nil)
    }

    @Test func cancelDecorationRemainsNativeTransfer() throws {
        let type: EvmDecoration.`Type` = try .outgoingEvm(to: address(), value: 0)
        let data = try data(swap: nil, type: type)
        let sections = sections(data)
        #expect(data.swap == nil)
        #expect(sections[0].fields[0].content is AmountField)
        #expect(sections[0].fields[1].content is AddressField)
        #expect(data.customSendButtonTitle == nil)
    }
}
