import Foundation
import HsToolKit

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
            if isContact(address: event.address) {
                return .trusted
            }
        }

        return .ignore
    }

    // A contact's address is trusted on every network, as its saved spam verdicts are cleared on every network
    private func isContact(address: String) -> Bool {
        let address = address.lowercased()
        return contactManager.all?.contains { contact in
            contact.addresses.contains { $0.address.lowercased() == address }
        } ?? false
    }
}
