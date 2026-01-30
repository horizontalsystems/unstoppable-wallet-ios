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
        for event in transaction.events.incoming {
            if isContact(address: event.address, blockchainType: transaction.blockchainType) {
                logger?.log(level: .debug, message: "CFilter: incoming from contact \(event.address.prefix(8))...")
                return .trusted
            }
        }

        for event in transaction.events.outgoing {
            if isContact(address: event.address, blockchainType: transaction.blockchainType) {
                logger?.log(level: .debug, message: "CFilter: outgoing to contact \(event.address.prefix(8))...")
                return .trusted
            }
        }

        return .ignore
    }

    private func isContact(address: String, blockchainType: BlockchainType) -> Bool {
        contactManager.name(blockchainType: blockchainType, address: address) != nil
    }
}
