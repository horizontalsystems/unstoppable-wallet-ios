import Foundation
import WalletCore

protocol TransferEventsProvider {
    var transferEvents: TransferEvents { get }
}

struct TransferEvents {
    let incoming: [TransferEvent]
    let outgoing: [TransferEvent]

    init(incoming: [TransferEvent] = [], outgoing: [TransferEvent] = []) {
        self.incoming = incoming
        self.outgoing = outgoing
    }

    var isEmpty: Bool {
        incoming.isEmpty && outgoing.isEmpty
    }
}

struct TransferEvent {
    let address: String
    let value: AppValue
}
