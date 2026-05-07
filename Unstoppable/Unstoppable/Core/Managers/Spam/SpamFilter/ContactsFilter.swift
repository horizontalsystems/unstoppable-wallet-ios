import Foundation
import HsToolKit
import MarketKit

final class ContactsFilter: SpamFilter {
    var identifier: String { "contacts_whitelist" }

    private let contactManager: ContactBookManager
    private let logger: Logger?

    init(contactManager: ContactBookManager, logger: Logger? = nil) {
        self.contactManager = contactManager
        self.logger = logger
    }

    func evaluate(_ transaction: SpamTransactionInfo) -> SpamFilterResult {
        for event in transaction.events.incoming + transaction.events.outgoing {
            if isContact(address: event.address, blockchainType: transaction.blockchainType) {
                return .trusted
            }
        }

        return .ignore
    }

    private func isContact(address: String, blockchainType: BlockchainType) -> Bool {
        contactManager.name(blockchainType: blockchainType, address: address) != nil
    }
}
