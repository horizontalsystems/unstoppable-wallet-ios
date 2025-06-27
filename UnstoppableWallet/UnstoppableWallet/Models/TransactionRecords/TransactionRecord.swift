import Foundation

class TransactionRecord {
    let source: TransactionSource
    let uid: String
    let transactionHash: String
    let transactionIndex: Int
    let blockHeight: Int?
    let confirmationsThreshold: Int?
    let date: Date
    let failed: Bool
    let spam: Bool

    var paginationRaw: String

    init(source: TransactionSource, uid: String, transactionHash: String, transactionIndex: Int, blockHeight: Int?, confirmationsThreshold: Int?, date: Date, failed: Bool, paginationRaw: String? = nil, spam: Bool = false) {
        self.source = source
        self.uid = uid
        self.transactionHash = transactionHash
        self.transactionIndex = transactionIndex
        self.blockHeight = blockHeight
        self.confirmationsThreshold = confirmationsThreshold
        self.date = date
        self.failed = failed
        self.spam = spam

        self.paginationRaw = paginationRaw ?? transactionHash
    }

    func status(lastBlockHeight: Int?) -> TransactionStatus {
        if failed {
            return .failed
        } else if let blockHeight, let lastBlockHeight {
            let threshold = confirmationsThreshold ?? 1
            let confirmations = lastBlockHeight - blockHeight + 1

            if confirmations >= threshold {
                return .completed
            } else {
                return .processing(progress: Double(max(0, confirmations)) / Double(threshold))
            }
        }

        return .pending
    }

    func lockState(lastBlockTimestamp _: Int?) -> TransactionLockState? {
        nil
    }

    open var mainValue: AppValue? {
        nil
    }
}

extension TransactionRecord: Identifiable {
    var id: String {
        uid
    }
}

extension TransactionRecord: Comparable {
    public static func < (lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        guard lhs.date == rhs.date else {
            return lhs.date > rhs.date
        }

        guard lhs.transactionIndex == rhs.transactionIndex else {
            return lhs.transactionIndex > rhs.transactionIndex
        }

        return lhs.paginationRaw > rhs.paginationRaw
    }

    public static func == (lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.uid == rhs.uid
    }
}

enum TransactionStatus {
    case failed
    case pending
    case processing(progress: Double)
    case completed

    var isPendingOrProcessing: Bool {
        switch self {
        case .pending, .processing: return true
        default: return false
        }
    }

    var isPending: Bool {
        switch self {
        case .pending: return true
        default: return false
        }
    }
}

extension TransactionStatus: Equatable {
    public static func == (lhs: TransactionStatus, rhs: TransactionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.failed, .failed): return true
        case (.pending, .pending): return true
        case let (.processing(lhsProgress), .processing(rhsProgress)): return lhsProgress == rhsProgress
        case (.completed, .completed): return true
        default: return false
        }
    }
}

extension TransactionRecord {
    var nftUids: Set<NftUid> {
        var nftUids = Set<NftUid>()

        switch self {
        case let record as EvmOutgoingTransactionRecord:
            if let nftUid = record.value.nftUid {
                nftUids.insert(nftUid)
            }

        case let record as ContractCallTransactionRecord:
            nftUids.formUnion(Set((record.incomingEvents + record.outgoingEvents).compactMap(\.value.nftUid)))

        case let record as ExternalContractCallTransactionRecord:
            nftUids.formUnion(Set((record.incomingEvents + record.outgoingEvents).compactMap(\.value.nftUid)))

        default: ()
        }

        return nftUids
    }
}

extension [TransactionRecord] {
    var nftUids: Set<NftUid> {
        var nftUids = Set<NftUid>()

        for record in self {
            nftUids = nftUids.union(record.nftUids)
        }

        return nftUids
    }
}
