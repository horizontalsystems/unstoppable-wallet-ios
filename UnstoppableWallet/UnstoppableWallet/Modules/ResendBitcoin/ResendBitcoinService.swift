import BitcoinCore
import Foundation
import Hodler
import HsExtensions
import HsToolKit
import MarketKit

class ResendBitcoinService {
    private var tasks = Set<AnyTask>()
    private let adapter: BitcoinBaseAdapter
    private let transactionHash: String
    private let currency: Currency
    private let price: Decimal?
    private let logger: Logger

    private(set) var replacementTransaction: ReplacementTransaction?
    private(set) var feeRange: Range<Int>
    let type: ResendTransactionType
    let token: Token

    @PostPublished private(set) var minFee: Int = 0
    @PostPublished private(set) var items: [ISendConfirmationViewItemNew] = []
    @PostPublished private(set) var state: State = .unsendable(error: nil)

    init(transactionRecord: BitcoinTransactionRecord, feeRange: Range<Int>, feeRateProvider: IFeeRateProvider, originalSize: Int, type: ResendTransactionType, adapter: BitcoinBaseAdapter, token: Token, currency: Currency, price: Decimal?, logger: Logger) {
        transactionHash = transactionRecord.transactionHash
        self.type = type
        self.feeRange = feeRange
        self.adapter = adapter
        self.token = token
        self.currency = currency
        self.price = price
        items = []
        self.logger = logger

        Task { [weak self, feeRateProvider] in
            if let feeRates = try? await feeRateProvider.feeRates() {
                let recommendedFee = originalSize * feeRates.recommended
                self?.syncReplacement(minFee: min(max(recommendedFee, feeRange.lowerBound), feeRange.upperBound))
            }
        }.store(in: &tasks)

        syncItems(replacement: nil, transactionRecord: transactionRecord)
    }

    private func currencyValue(coinAmount: Decimal) -> CurrencyValue? {
        price.flatMap { CurrencyValue(currency: currency, value: $0 * coinAmount) }
    }

    private func syncItems(replacement: ReplacementTransaction?, transactionRecord: BitcoinTransactionRecord) {
        replacementTransaction = replacement

        guard let record = transactionRecord as? BitcoinOutgoingTransactionRecord else {
            return
        }

        var items = [ISendConfirmationViewItemNew]()

        if let address = record.to, case let .coinValue(_, value) = record.value {
            items.append(
                SendConfirmationAmountViewItem(coinValue: .init(kind: .token(token: token), value: value), currencyValue: currencyValue(coinAmount: value), receiver: Address(raw: address), sentToSelf: record.sentToSelf)
            )
        }

        if let memo = record.memo {
            items.append(SendConfirmationMemoViewItem(memo: memo))
        }

        if let lockInfo = record.lockInfo {
            items.append(SendConfirmationLockUntilViewItem(lockValue: HodlerPlugin.LockTimeInterval.title(lockTimeInterval: lockInfo.lockTimeInterval)))
        }

        if case let .coinValue(_, feeValue) = record.fee {
            items.append(
                SendConfirmationFeeViewItem(coinValue: .init(kind: .token(token: token), value: feeValue), currencyValue: currencyValue(coinAmount: feeValue))
            )
        }

        if let replacement, !replacement.replacedTransactionHashes.isEmpty {
            items.append(ReplacedTransactionHashViewItem(hashes: replacement.replacedTransactionHashes))
        }

        self.items = items
    }
}

extension ResendBitcoinService {
    func syncReplacement(minFee: Int) {
        self.minFee = minFee

        Task { [weak self, transactionHash, adapter, type] in
            do {
                switch type {
                case .speedUp:
                    let (replacement, record) = try adapter.speedUpTransaction(transactionHash: transactionHash, minFee: minFee)
                    self?.syncItems(replacement: replacement, transactionRecord: record)
                case .cancel:
                    let (replacement, record) = try adapter.cancelTransaction(transactionHash: transactionHash, minFee: minFee)
                    self?.syncItems(replacement: replacement, transactionRecord: record)
                }
                self?.state = .sendable
            } catch {
                self?.state = .unsendable(error: error)
            }
        }.store(in: &tasks)
    }

    func send() {
        guard let replacementTransaction else {
            return
        }

        let actionLogger = logger.scoped(with: "\(Int.random(in: 0 ..< 1_000_000))")
        actionLogger.debug("Confirm clicked", save: true)

        Task { [weak self, replacementTransaction, adapter] in
            self?.state = .sending
            do {
                _ = try adapter.send(replacementTransaction: replacementTransaction)
                self?.state = .sent
                actionLogger.debug("Send success", save: true)
            } catch {
                self?.state = .failed(error: error)
                actionLogger.debug("Send error: \(error)", save: true)
            }
        }.store(in: &tasks)
    }
}

extension ResendBitcoinService {
    enum State {
        case unsendable(error: Error?)
        case sendable
        case sending
        case sent
        case failed(error: Error)
    }
}
