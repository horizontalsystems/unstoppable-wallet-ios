@testable import BitcoinCore
import Foundation
import Hodler
import MarketKit
import SwiftUI
import Testing
import UIKit
@testable import WalletCore

struct BitcoinResendTests {
    private let token = Token(coin: Coin(uid: "bitcoin", name: "Bitcoin", code: "BTC"),
                              blockchain: Blockchain(type: .bitcoin, name: "Bitcoin", explorerUrl: nil), type: .native, decimals: 8)
    private let currency = Currency(code: "USD", symbol: "$", decimal: 2)
    private let recipient = "bc1qrecipient000000000000000000000000000000"
    private let ownAddress = "bc1qownaddress00000000000000000000000000000"

    private func request(type: ResendTransactionType = .speedUp) -> BitcoinResendRequest {
        let record = BitcoinOutgoingTransactionRecord(
            token: token, source: .init(blockchainType: .bitcoin, meta: nil), uid: "confirmed", transactionHash: String(repeating: "a", count: 64),
            transactionIndex: 0, blockHeight: 900_000, confirmationsThreshold: 3, date: Date(timeIntervalSince1970: 1_700_000_000),
            fee: Decimal(string: "0.00001"), failed: false, lockInfo: nil, conflictingHash: nil, showRawTransaction: false,
            amount: Decimal(string: "0.00123456")!, to: recipient, sentToSelf: false, memo: "Test memo", replaceable: false
        )
        return BitcoinResendRequest(token: token, transaction: record, type: type)
    }

    private func preparedData(type: ResendTransactionType = .speedUp, fee: Int = 1200, recommendedFee: Int? = nil) -> BitcoinResendData {
        let cancel = type == .cancel
        let address = cancel ? ownAddress : recipient
        let amount = cancel ? 123_256 : 123_456
        let info = TransactionInfo(
            uid: "replacement", transactionHash: String(repeating: "b", count: 64), transactionIndex: 0,
            inputs: [], outputs: [], amount: amount, type: .outgoing, fee: fee,
            blockHeight: nil, timestamp: 1_700_000_000, status: .new, conflictingHash: nil, rbfEnabled: true
        )
        let replacement = ReplacementTransaction(mutableTransaction: MutableTransaction(), info: info,
                                                 replacedTransactionHashes: [request().transaction.transactionHash])
        let record = BitcoinOutgoingTransactionRecord(
            token: token, source: .init(blockchainType: .bitcoin, meta: nil), uid: info.uid, transactionHash: info.transactionHash,
            transactionIndex: 0, blockHeight: nil, confirmationsThreshold: 3, date: Date(timeIntervalSince1970: 1_700_000_000),
            fee: Decimal(fee) / 100_000_000, failed: false, lockInfo: nil, conflictingHash: nil, showRawTransaction: false,
            amount: Decimal(amount) / 100_000_000, to: address, sentToSelf: cancel,
            memo: cancel ? nil : "Test memo", replaceable: true
        )
        return BitcoinResendData(record: record, type: type, recommendedFee: recommendedFee, replacement: replacement)
    }

    @Test func halfOpenFeeRange() {
        #expect(BitcoinResendTransactionService.initialMinFee(recommended: 1000, range: 100 ..< 500) == 499)
        #expect(BitcoinResendTransactionService.initialMinFee(recommended: 1, range: 100 ..< 500) == 100)
        #expect(BitcoinResendTransactionService.initialMinFee(recommended: 200, range: 100 ..< 500) == 200)
        #expect(BitcoinResendTransactionService.initialMinFee(recommended: 200, range: 100 ..< 100) == nil)
        #expect(BitcoinResendTransactionService.initialMinFee(recommended: 200, range: 100 ..< 101) == 100)
    }

    @MainActor @Test func minFeePersistsAcrossRefresh() async throws {
        var rateRequests = 0
        let service = BitcoinResendTransactionService(originalSize: 200, feeRange: 100 ..< 10000) {
            rateRequests += 1
            return 3
        }
        try await service.sync()
        #expect(service.minFee == 600)
        service.set(minFeeText: "1234")
        try await service.sync()
        #expect(service.recommendedFee == 600)
        #expect(rateRequests == 1)
        #expect(service.minFee == 1234)
        guard case let .bitcoinResend(minFee, _) = service.transactionSettings else {
            Issue.record("Expected absolute replacement fee settings")
            return
        }
        #expect(minFee == 1234)
        #expect(service.transactionSettings?.satoshiPerByte == nil)
    }

    @MainActor @Test func failedRecommendationStillAllowsManualFee() async throws {
        var rateRequests = 0
        let service = BitcoinResendTransactionService(originalSize: 200, feeRange: 100 ..< 10000) {
            rateRequests += 1
            throw URLError(.cannotConnectToHost)
        }
        let prepared = preparedData()
        let replacement = try #require(prepared.replacement)
        var builds = 0
        let handler = BitcoinResendHandler(request: request()) { minFee in
            #expect(minFee == 1200)
            builds += 1
            return (replacement, prepared.record)
        } sendReplacement: { _ in
            Issue.record("Preparing a manual fee must not broadcast")
        }

        try await service.sync()
        let initial = try await handler.sendData(transactionSettings: service.transactionSettings)
        #expect(!initial.canSend)
        #expect(service.minFeeText.isEmpty)
        #expect(service.recommendedFee == nil)
        #expect(builds == 0)

        service.set(minFeeText: "1200")
        try await service.sync()
        let result = try await handler.sendData(transactionSettings: service.transactionSettings)
        let data = try #require(result as? BitcoinResendData)
        #expect(data.canSend)
        #expect(data.replacement?.mutableTransaction === replacement.mutableTransaction)
        #expect(data.recommendedFee == nil)
        #expect(service.minFee == 1200)
        #expect(rateRequests == 1)
        #expect(builds == 1)
    }

    @MainActor @Test func cancelledRecommendationCanBeRetried() async throws {
        var rateRequests = 0
        let service = BitcoinResendTransactionService(originalSize: 200, feeRange: 100 ..< 10000) {
            rateRequests += 1
            if rateRequests == 1 { throw CancellationError() }
            return 3
        }

        await #expect(throws: CancellationError.self) { try await service.sync() }
        #expect(service.recommendedFee == nil)
        try await service.sync()
        #expect(service.minFee == 600)
        #expect(rateRequests == 2)
    }

    @MainActor @Test func invalidInputIsNotRestoredByRefresh() async throws {
        let service = BitcoinResendTransactionService(originalSize: 200, feeRange: 100 ..< 500) { 3 }
        try await service.sync()
        #expect(service.minFee == 499)
        for input in ["", "-1", "99", "500", "not a number", "999999999999999999999999"] {
            service.set(minFeeText: input)
            try await service.sync()
            #expect(service.minFeeText == input)
            #expect(service.transactionSettings == nil)
            #expect(service.cautions.contains { $0.type == .error })
        }
        service.set(minFeeText: "100")
        service.step(.down)
        #expect(service.minFee == 100)
        service.set(minFeeText: "499")
        service.step(.up)
        #expect(service.minFee == 499)
    }

    @Test func preparedReplacementIsShownAndSent() async throws {
        for type in [ResendTransactionType.speedUp, .cancel] {
            let prepared = preparedData(type: type)
            let replacement = try #require(prepared.replacement)
            var sends = 0
            let handler = BitcoinResendHandler(request: request(type: type)) { minFee in
                #expect(minFee == 1000)
                return (replacement, prepared.record)
            } sendReplacement: { sent in
                #expect(sent.mutableTransaction === replacement.mutableTransaction)
                #expect(sent.replacedTransactionHashes == replacement.replacedTransactionHashes)
                sends += 1
            }
            let result = try await handler.sendData(transactionSettings: .bitcoinResend(minFee: 1000))
            let data = try #require(result as? BitcoinResendData)
            #expect(data.canSend)
            #expect(data.record === prepared.record)
            #expect(data.record.to == (type == .cancel ? ownAddress : recipient))
            #expect(data.record.fee?.value == Decimal(string: "0.000012"))
            #expect(data.replacedTransactionCount == 1)
            try await handler.send(data: data)
            #expect(sends == 1)
        }
    }

    @Test func builderReceivesAbsoluteFeeAndKeepsLocalizedFailure() async throws {
        let handler = BitcoinResendHandler(request: request()) { minFee in
            #expect(minFee == 1234)
            throw ReplacementTransactionBuildError.alreadyReplaced
        } sendReplacement: { _ in
            Issue.record("Failed replacement must not broadcast")
        }
        let result = try await handler.sendData(transactionSettings: .bitcoinResend(minFee: 1234))
        let data = try #require(result as? BitcoinResendData)
        #expect(!data.canSend)
        #expect(data.transactionError as? ReplacementTransactionBuildError == .alreadyReplaced)
        #expect(data.cautions(baseToken: token, currency: currency, rates: [:]).first?.type == .error)
        await #expect(throws: (any Error).self) { try await handler.send(data: data) }
    }

    @Test func sectionsReuseModernRows() throws {
        for type in [ResendTransactionType.speedUp, .cancel] {
            let data = preparedData(type: type)
            let sections = data.sections(baseToken: token, currency: currency, rates: ["bitcoin": 60000])
            #expect(sections.count == 3)
            #expect(sections[0].fields.count == 2)
            #expect(sections[0].isFlow)
            #expect(!sections[1].isFlow)
            #expect(!sections[1].isMain)
            #expect(sections[0].fields[0].content is SimpleValueField)
            #expect(sections[0].fields[1].content is AmountField)
            let address = try #require(sections[1].fields[0].content as? RecipientField)
            #expect(address.value == (type == .cancel ? ownAddress : recipient))
            #expect(address.title == (type == .cancel ? "send.confirmation.own" : "send.confirmation.to").localized)
            let count = try #require(sections[1].fields.last?.content as? SimpleValueField)
            #expect(count.value.description == "1")
            let fee = try #require(sections[2].fields[0].content as? FeeField)
            #expect(fee.initialFlipped)
        }
    }

    @Test func clearingFeeKeepsCancelAddressButDisablesSend() async throws {
        let prepared = preparedData(type: .cancel)
        let replacement = try #require(prepared.replacement)
        let handler = BitcoinResendHandler(request: request(type: .cancel)) { _ in
            (replacement, prepared.record)
        } sendReplacement: { _ in
            Issue.record("Invalid fee must not broadcast")
        }
        _ = try await handler.sendData(transactionSettings: .bitcoinResend(minFee: 1200))
        let result = try await handler.sendData(transactionSettings: nil)
        let data = try #require(result as? BitcoinResendData)
        #expect(data.record.to == ownAddress)
        #expect(data.record.sentToSelf)
        #expect(!data.canSend)
        #expect(data.replacement == nil)
        await #expect(throws: (any Error).self) { try await handler.send(data: data) }
        let feeSection = try #require(data.sections(baseToken: token, currency: currency, rates: [:]).last)
        #expect((feeSection.fields.first?.content as? FeeField)?.amountData == nil)
    }

    @Test func stuckWarningUsesPreparedFee() {
        let low = preparedData(fee: 1200, recommendedFee: 1500)
        #expect(low.cautions(baseToken: token, currency: currency, rates: [:]).first?.type == .warning)
        let enough = preparedData(fee: 1500, recommendedFee: 1500)
        #expect(enough.cautions(baseToken: token, currency: currency, rates: [:]).isEmpty)
    }

    @MainActor @Test func renderBitcoinForms() async throws {
        let service = BitcoinResendTransactionService(originalSize: 200, feeRange: 1000 ..< 10000) { 6 }
        try await service.sync()
        for type in [ResendTransactionType.speedUp, .cancel] {
            let data = preparedData(type: type)
            let sections = data.sections(baseToken: token, currency: currency, rates: ["bitcoin": 60000])
            let content = VStack(spacing: 16) {
                sections.sectionViews
                BitcoinResendFeeView(service: service)
            }
            .padding(16)
            .frame(width: 390)
            .background(Color.themeTyler)
            .environment(\.colorScheme, .light)

            // InputTextView wraps UITextField, which SwiftUI ImageRenderer cannot render.
            let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
            let window = UIWindow(windowScene: scene)
            let controller = UIHostingController(rootView: content)
            window.rootViewController = controller
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
            window.isHidden = false
            defer { window.isHidden = true }
            controller.view.frame = window.bounds
            controller.view.layoutIfNeeded()
            let png = UIGraphicsImageRenderer(bounds: controller.view.bounds).pngData { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            if #available(iOS 26.0, *) {
                Attachment.record(png, named: "bitcoin-\(type.rawValue).png")
            }
        }
    }
}
