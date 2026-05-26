import Foundation
import WalletCore

extension TransactionRecord {
    var nftUids: Set<NftUid> {
        var nftUids = Set<NftUid>()

        switch self {
        case let record as EvmOutgoingTransactionRecord:
            if let nftUid = (record.value.kind as? NftAppValue)?.nftUidValue {
                nftUids.insert(nftUid)
            }

        case let record as ContractCallTransactionRecord:
            nftUids.formUnion(Set((record.incomingEvents + record.outgoingEvents).compactMap { ($0.value.kind as? NftAppValue)?.nftUidValue }))

        case let record as ExternalContractCallTransactionRecord:
            nftUids.formUnion(Set((record.incomingEvents + record.outgoingEvents).compactMap { ($0.value.kind as? NftAppValue)?.nftUidValue }))

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
