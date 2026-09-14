import BitcoinCore
import Combine
import Foundation
import MarketKit

class BitcoinResendTransactionService: TransactionService, ObservableObject {
    let feeRange: Range<Int>
    private let originalSize: Int
    private let recommendedFeeRate: () async throws -> Int
    private var initialized = false
    private var edited = false
    private let updateSubject = PassthroughSubject<Void, Never>()

    @Published private(set) var minFeeText = ""
    @Published private(set) var recommendedFee: Int?

    init(originalSize: Int, feeRange: Range<Int>, recommendedFeeRate: @escaping () async throws -> Int) {
        self.originalSize = originalSize
        self.feeRange = feeRange
        self.recommendedFeeRate = recommendedFeeRate
    }

    override class func instance(sendData: SendData, baseToken: Token, initialTransactionSettings _: InitialTransactionSettings?) -> ITransactionService? {
        guard case let .bitcoinResend(request) = sendData,
              let adapter = Core.shared.adapterManager.adapter(for: baseToken) as? BitcoinBaseAdapter,
              let (size, range) = replacementInfo(adapter: adapter, request: request), !range.isEmpty
        else { return nil }
        guard let provider = Core.shared.feeRateProviderFactory.provider(blockchainType: baseToken.blockchainType) else { return nil }
        return BitcoinResendTransactionService(originalSize: size, feeRange: range) {
            try await provider.feeRates().recommended
        }
    }

    static func replacementInfo(adapter: BitcoinBaseAdapter, request: BitcoinResendRequest) -> (Int, Range<Int>)? {
        switch request.type {
        case .speedUp: return adapter.speedUpTransactionInfo(transactionHash: request.transaction.transactionHash)
        case .cancel: return adapter.cancelTransactionInfo(transactionHash: request.transaction.transactionHash)
        }
    }

    var minFee: Int? { Int(minFeeText) }

    static func initialMinFee(recommended: Int, range: Range<Int>) -> Int? {
        guard !range.isEmpty else { return nil }
        return min(max(recommended, range.lowerBound), range.upperBound - 1)
    }

    func set(minFeeText: String) {
        edited = true
        self.minFeeText = minFeeText
        updateSubject.send()
    }

    func step(_ direction: StepChangeButtonsViewDirection) {
        guard !feeRange.isEmpty else { return }
        let current = minFee ?? feeRange.lowerBound
        let next: Int
        switch direction {
        case .down: next = current > feeRange.lowerBound ? current - 1 : feeRange.lowerBound
        case .up: next = current < feeRange.upperBound - 1 ? current + 1 : feeRange.upperBound - 1
        }
        if let next = Self.initialMinFee(recommended: next, range: feeRange) {
            set(minFeeText: String(next))
        }
    }
}

extension BitcoinResendTransactionService: ITransactionService {
    var transactionSettings: TransactionSettings? {
        guard let minFee, feeRange.contains(minFee) else { return nil }
        return .bitcoinResend(minFee: minFee, recommendedFee: recommendedFee)
    }

    var modified: Bool { edited }
    var updatePublisher: AnyPublisher<Void, Never> { updateSubject.eraseToAnyPublisher() }

    var cautions: [CautionNew] {
        guard let minFee, feeRange.contains(minFee) else {
            let message = (minFee.map { $0 >= feeRange.upperBound } ?? false) ? "alert.unable_to_replace" : "alert.fee_too_low"
            return [.init(title: "alert.error".localized, text: message.localized, type: .error)]
        }
        return []
    }

    func sync() async throws {
        // Like the old replacement service, load the recommendation once. Editing an
        // absolute fee and the send VM's periodic rebuild need no fee-rate request.
        guard !initialized else { return }
        let rate: Int
        do {
            rate = try await recommendedFeeRate()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            // A recommendation is optional: keep the form available for a manual fee.
            await MainActor.run { initialized = true }
            return
        }
        try Task.checkCancellation()
        let (recommended, overflow) = originalSize.multipliedReportingOverflow(by: rate)
        guard !overflow, let initial = Self.initialMinFee(recommended: recommended, range: feeRange) else {
            throw ReplacementTransactionBuildError.unableToReplace
        }
        await MainActor.run {
            recommendedFee = recommended
            if !initialized {
                if !edited { minFeeText = String(initial) }
                initialized = true
            }
        }
    }
}
