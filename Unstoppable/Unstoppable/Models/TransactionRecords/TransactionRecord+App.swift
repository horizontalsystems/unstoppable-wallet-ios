import Foundation
import WalletCore

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
