import BigInt
import Combine
import Eip20Kit
import EvmKit
import Foundation
import HsToolKit
import NftKit
import RxSwift

protocol IIncomingTransaction {
    var incomingValue: AppValue { get }
}

class SpamManager {
    private let queue = DispatchQueue(label: "\(AppConfig.label).spam-manager", qos: .userInitiated)

    private let allowedTransactionSources: [TransactionSource] = EvmBlockchainManager.blockchainTypes.map { .init(blockchainType: $0, meta: nil) } + [.init(blockchainType: .stellar, meta: nil), .init(blockchainType: .tron, meta: nil)]

    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private var cancellables = Set<AnyCancellable>()
    private let coinValueLimits: [String: Decimal] = AppConfig.spamCoinValueLimits

    private let storage: SpamAddressStorage
    private let accountManager: AccountManager
    private let transactionAdapterManager: TransactionAdapterManager
    private var logger: Logger?

    private let factory = TransferEventFactory()

    init(storage: SpamAddressStorage, accountManager: AccountManager, transactionAdapterManager: TransactionAdapterManager, logger: Logger? = nil) {
        self.storage = storage
        self.accountManager = accountManager
        self.transactionAdapterManager = transactionAdapterManager
        self.logger = logger

        subscribe(disposeBag, transactionAdapterManager.adaptersReadyObservable) { [weak self] in
            self?.subscribeAdapters()
        }
    }

    private func subscribeAdapters() {
        adaptersDisposeBag = DisposeBag()
        logger?.log(level: .debug, message: "Total adapters to subscribe: \(transactionAdapterManager.adapterMap.count)")
        for (source, adapter) in transactionAdapterManager.adapterMap {
            subscribeAdapter(adapter: adapter, source: source)
        }
    }

    private func subscribeAdapter(adapter: ITransactionsAdapter, source: TransactionSource) {
        // subscribe for updates. For each updates we must handle all new transactions from database
        subscribe(adaptersDisposeBag, adapter.transactionsObservable(token: nil, filter: .all, address: nil)) { [weak self] records in
            self?.logger?.log(level: .debug, message: "Handle NEW \(records.count) records. For \(source.blockchainType.uid)")
            self?.serialSync(source: source)
        }

        logger?.log(level: .debug, message: "Handle OLD records from DB. For \(source.blockchainType.uid)")
        serialSync(source: source)
    }

    private func serialSync(source: TransactionSource) {
        queue.async { [weak self] in
            Task { [weak self] in
                await self?.sync(source: source)
            }
        }
    }

    private func sync(source: TransactionSource) async {
        guard let adapter = transactionAdapterManager.adapter(for: source) else {
            logger?.log(level: .error, message: "Can't found adapter. For \(source.blockchainType.uid)")
            return
        }
        guard let accountUid = accountManager.activeAccount?.id else {
            logger?.log(level: .error, message: "Can't found accountID")
            return
        }

        let spamScanState = try? storage.find(blockchainTypeUid: source.blockchainType.uid, accountUid: accountUid)

        let transactions = await withCheckedContinuation { continuation in
            adapter
                .allTransactionsAfter(paginationData: spamScanState?.lastPaginationData)
                .subscribe(
                    onSuccess: { transactions in
                        continuation.resume(returning: transactions)
                    }
                )
                .disposed(by: disposeBag)
        }

        let lastPaginationData = handle(transactions: transactions, source: source)

        if let lastPaginationData {
            let spamScanState = SpamScanState(blockchainTypeUid: source.blockchainType.uid, accountUid: accountUid, lastPaginationData: lastPaginationData)
            try? storage.save(spamScanState: spamScanState)
        }
    }

    private func handle(transactions: [TransactionRecord], source: TransactionSource) -> String? {
        let txWithEvents = transactions.map { (hash: $0.transactionHash, events: factory.transferEvents(transactionRecord: $0)) }

        var spamAddresses = [SpamAddress]()
        for item in txWithEvents {
            guard !item.events.isEmpty, let hash = item.hash.hs.hexData else { // convert string hash to data
                continue
            }

            let result = Self.handleSpamAddresses(events: item.events)

            if !result.isEmpty {
                for address in result { // save all addresses with tx Hash
                    let address = Address(raw: address, blockchainType: source.blockchainType)
                    spamAddresses.append(SpamAddress(transactionHash: hash, address: address))
                }
            }
        }

        do {
            try storage.save(spamAddresses: spamAddresses)
        } catch {}

        return transactions.sorted().first?.paginationRaw
    }
}

extension SpamManager {
    func find(address: String) -> SpamAddress? {
        try? storage.find(address: address)
    }
}

extension SpamManager {
    private static func isSpam(appValue: AppValue) -> Bool {
        let spamCoinLimits = AppConfig.spamCoinValueLimits
        let value = appValue.value

        var limit: Decimal = 0
        switch appValue.kind {
        case let .token(token):
            limit = spamCoinLimits[token.coin.code] ?? 0
        case let .coin(coin, _):
            limit = spamCoinLimits[coin.code] ?? 0
        case let .jetton(jetton):
            limit = spamCoinLimits[jetton.symbol] ?? 0
        case let .stellar(asset):
            limit = spamCoinLimits[asset.code] ?? 0
        case .nft:
            if value > 0 {
                return false
            }
        case .raw, .eip20Token: return true
        }

        return limit > value
    }

    private static func handleSpamAddresses(events: [TransferEvent]) -> [String] {
        var spamTokenSenders = [String]()

        var nativeSenders = [String]()
        var nativeKind: AppValue.Kind?
        var nativeSpendedValue: Decimal = 0

        for event in events {
            if case let .token(token) = event.value.kind, token.type == .native { // handle native transaction values
                nativeKind = event.value.kind
                nativeSenders.append(event.address)
                nativeSpendedValue += event.value.value
            } else {
                if isSpam(appValue: event.value) {
                    spamTokenSenders.append(event.address)
                }
            }
        }

        if let nativeKind, !nativeSenders.isEmpty { // if all native received money < minimal limit add all addresses to spam
            let nativeAppValue = AppValue(kind: nativeKind, value: nativeSpendedValue)

            if isSpam(appValue: nativeAppValue) {
                spamTokenSenders.append(contentsOf: nativeSenders)
            }
        }

        return spamTokenSenders
    }

    static func isSpam(events: [TransferEvent]) -> Bool {
        !handleSpamAddresses(events: events).isEmpty
    }
}
