import BigInt
import EvmKit
import Foundation
import MarketKit
import OneInchKit
import SwiftUI
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
            swap: swap, transactionData: transactionData, transactionError: nil, gasPrice: .legacy(gasPrice: 10_000_000_000),
            evmFeeData: EvmFeeData(gasLimit: 54321, surchargedGasLimit: 54321), nonce: 7
        )
    }

    private func sections(_ data: EvmResendData) -> [SendDataSection] {
        data.sections(baseToken: baseToken, currency: currency, rates: ["ethereum": 3000, "tether": 1])
    }

    private func expectSettings(_ section: SendDataSection) throws {
        #expect(!section.isFlow)
        let nonce = try #require(section.fields.compactMap { $0.content as? SimpleValueField }.last)
        #expect(nonce.title.description == "send.confirmation.nonce".localized)
        #expect(nonce.value.description == "7")
        let fee = try #require(section.fields.last?.content as? FeeField)
        #expect(fee.initialFlipped)
        let flipData = FlipRow.TokenFeeData(amountData: fee.amountData)
        #expect(flipData.text(flipped: fee.initialFlipped) == fee.amountData?.appValue.formattedFull())
    }

    private func expectSwapCard(_ section: SendDataSection, incoming: Bool, token: MarketKit.Token, value: Decimal, limited: Bool) throws {
        #expect(section.isFlow)
        #expect(section.fields.count == 2)
        let header = try #require(section.fields[0].content as? SimpleValueField)
        #expect(header.title.description == (incoming ? "swap.you_get" : "swap.you_pay").localized)
        #expect(header.value.description == token.coin.name)
        #expect(header.icon == (incoming ? "arrow_medium_main_down_left_20" : "arrow_medium_main_up_right_20"))
        let amount = try #require(section.fields[1].content as? SwapAmountField)
        #expect(amount.token == token)
        #expect(amount.appValue.value == value)
        #expect(amount.incoming == incoming)
        #expect(amount.suffix == (limited ? (incoming ? "swap.amount_min" : "swap.amount_max").localized : nil))
        if let suffix = amount.suffix {
            #expect(amount.amountText.hasSuffix(suffix))
        }
    }

    @Test(arguments: [true, false]) func uniswapKeepsSeparatePayGetAndSettingsCards(exactInput: Bool) throws {
        let swap = try #require(decodedSwap(uniswap(exactInput: exactInput)))
        let data = try data(swap: swap)
        let sections = sections(data)
        #expect(sections.count == 4) // Pay, Get, optional recipient, settings.
        try expectSwapCard(sections[0], incoming: false, token: baseToken, value: 1, limited: !exactInput)
        try expectSwapCard(sections[1], incoming: true, token: outputToken, value: 2, limited: exactInput)
        let recipient = try #require(sections[2].fields.first?.content as? AddressField)
        #expect(recipient.value == (try address("3").eip55))
        try expectSettings(sections[3])
        #expect(data.rateCoins.map(\.uid) == ["ethereum", "tether"])
        #expect(data.transactionData?.input == Data([0xAB, 0xCD]))
        #expect(data.evmFeeData?.surchargedGasLimit == 54321)
        #expect(data.canSend)
    }

    @Test(arguments: [true, false]) func oneInchUsesSamePayGetAndSettingsLayout(unoswap: Bool) throws {
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
        #expect(sections.count == 3)
        try expectSwapCard(sections[0], incoming: false, token: baseToken, value: 1, limited: false)
        try expectSwapCard(sections[1], incoming: true, token: outputToken, value: 2, limited: true)
        try expectSettings(sections[2])
    }

    @Test func missingTokenMetadataPreservesContractFallback() throws {
        let swap = try EvmResendSwapData(decoration: uniswap(), baseToken: baseToken) { _ in nil }
        #expect(swap == nil)
        let data = try data(swap: swap)
        let sections = sections(data)
        #expect(sections.count == 2)
        try expectSettings(sections[1])
        let fields = sections.flatMap(\.fields).compactMap { $0.content as? SimpleValueField }
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

    @Test(arguments: [Decimal(0), Decimal(5)]) func approveAndRevokeReuseSharedFields(value: Decimal) throws {
        let type: EvmDecoration.`Type` = try .approveEip20(spender: address("3"), value: value, token: outputToken)
        let data = try data(swap: nil, type: type)
        let sections = sections(data)
        #expect(sections.count == 2)
        let amount = try #require(sections[0].fields.first?.content as? AmountField)
        let spender = try #require(sections[1].fields.first?.content as? RecipientField)
        try expectSettings(sections[1])
        #expect(amount.token == outputToken)
        #expect(spender.value == (try address("3").eip55))
        #expect(data.customSendButtonTitle == nil)
    }

    @Test(arguments: [Decimal(0), Decimal(1)]) func nativeSendAndCancelUseAmountAddressFlow(value: Decimal) throws {
        let type: EvmDecoration.`Type` = try .outgoingEvm(to: address(), value: value)
        let sections = try sections(data(swap: nil, type: type))
        #expect(sections.count == 2)
        #expect(sections[0].isFlow)
        #expect(sections[0].fields.count == 2)
        #expect(sections[0].fields[0].content is AmountField)
        let addressField = try #require(sections[0].fields[1].content as? AddressField)
        #expect(addressField.value == (try address().eip55))
        try expectSettings(sections[1])
    }

    @Test func sharedFeeDefaultStillStartsWithFiat() {
        let fee = FeeField(title: "Fee", amountData: nil)
        #expect(!fee.initialFlipped)
    }

    @MainActor @Test func renderReplacementForms() throws {
        let oneInch = try OneInchUnoswapDecoration(
            contractAddress: address(), tokenIn: .evmCoin, tokenOut: .eip20Coin(address: address("2"), tokenInfo: nil),
            amountIn: 1_000_000_000_000_000_000, amountOut: .extremum(value: 2_000_000), params: []
        )
        let cases: [(String, EvmResendData)] = try [
            ("oneinch", data(swap: decodedSwap(oneInch))),
            ("native", data(swap: nil, type: .outgoingEvm(to: address(), value: 1))),
            ("cancel", data(swap: nil, type: .outgoingEvm(to: address(), value: 0))),
            ("approve", data(swap: nil, type: .approveEip20(spender: address(), value: 5, token: outputToken))),
            ("swap-exact-input", data(swap: decodedSwap(uniswap()))),
            ("swap-exact-output", data(swap: decodedSwap(uniswap(exactInput: false)))),
        ]
        for (name, data) in cases {
            let renderer = ImageRenderer(content:
                VStack(spacing: 16) {
                    sections(data).sectionViews
                }
                .padding(16)
                .frame(width: 390)
                .background(Color.themeTyler)
                .environment(\.colorScheme, .light)
            )
            renderer.scale = 2
            let png = try #require(renderer.uiImage?.pngData())
            if #available(iOS 26.0, *) {
                Attachment.record(png, named: "resend-\(name).png")
            }
        }
    }
}
