import Foundation
import MarketKit
import TronKit

class TronExternalContractCallTransactionRecord: TronTransactionRecord {
    let incomingEvents: [TransferEvent]
    let outgoingEvents: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseToken: Token, incomingEvents: [TransferEvent], outgoingEvents: [TransferEvent]) {
        self.incomingEvents = incomingEvents
        self.outgoingEvents = outgoingEvents

        let spam = TransactionRecord.isSpam(appValues: (incomingEvents + outgoingEvents).map(\.value))

        super.init(source: source, transaction: transaction, baseToken: baseToken, ownTransaction: false, spam: spam)
    }

    var combinedValues: ([AppValue], [AppValue]) {
        combined(incomingEvents: incomingEvents, outgoingEvents: outgoingEvents)
    }

    override var mainValue: AppValue? {
        let (incomingValues, outgoingValues) = combinedValues

        if incomingValues.count == 1, outgoingValues.isEmpty {
            return incomingValues[0]
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return outgoingValues[0]
        } else {
            return nil
        }
    }

    override var rateTokens: [Token?] {
        super.rateTokens + incomingEvents.map(\.value.token) + outgoingEvents.map(\.value.token)
    }

    override func internalSections(status _: TransactionStatus, lastBlockInfo _: LastBlockInfo?, rates: [Coin: CurrencyValue], nftMetadata: [NftUid: NftAssetBriefMetadata], hidden: Bool) -> [Section] {
        var sections = [Section]()

        for event in outgoingEvents {
            sections.append(.init(fields: sendFields(appValue: event.value, to: event.address, burn: event.address == zeroAddress, rates: rates, nftMetadata: nftMetadata, hidden: hidden)))
        }

        for event in incomingEvents {
            sections.append(.init(fields: receiveFields(appValue: event.value, from: event.address, mint: event.address == zeroAddress, rates: rates, nftMetadata: nftMetadata, hidden: hidden)))
        }

        return sections
    }
}
