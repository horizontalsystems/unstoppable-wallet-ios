import Foundation

class ContactBookHelper {
    // Merge contacts with replace older contacts by newer
    func mergeNewer(lhs: [Contact], rhs: [Contact]) -> [Contact] {
        let left = Set(lhs)
        let right = Set(rhs)

        let difference = left.symmetricDifference(right)
        let intersectionLeft = left.intersection(right)

        let mergedNewer = intersectionLeft.map { lContact in
            if let rContact = right.first(where: { $0.uid == lContact.uid }),
               rContact.modifiedAt > lContact.modifiedAt
            {
                return rContact
            }
            return lContact
        }

        return difference + mergedNewer
    }

    // Merge deleted contacts with replace older contacts by newer
    func mergeNewer(lhs: [DeletedContact], rhs: [DeletedContact]) -> [DeletedContact] {
        let left = Set(lhs)
        let right = Set(rhs)

        let difference = left.symmetricDifference(right)
        let intersectionLeft = left.intersection(right)

        let mergedNewer = intersectionLeft.map { lContact in
            if let rContact = right.first(where: { $0.uid == lContact.uid }),
               rContact.deletedAt > lContact.deletedAt
            {
                return rContact
            }
            return lContact
        }

        return difference + mergedNewer
    }

    // Remove from contacts all deleted lately and remove from deleted array all changed lately
    func filter(contacts: [Contact], deleted: [DeletedContact]) -> (newContacts: [Contact], newDeleted: [DeletedContact]) {
        var deleted = deleted

        let contacts = contacts.filter { contact in
            if let deletedIndex = deleted.firstIndex(where: { contact.uid == $0.uid }) {
                if deleted[deletedIndex].deletedAt > contact.modifiedAt {
                    return false
                } else {
                    deleted.remove(at: deletedIndex)
                }
            }
            return true
        }

        return (newContacts: contacts, newDeleted: deleted)
    }

    // check if contacts and deleted both identical in contact books
    func identical(lhs: ContactBook, rhs: ContactBook) -> Bool {
        let lhsContacts = lhs.contacts.map { EqualContactData(uid: $0.uid, timestamp: $0.modifiedAt) }
        let rhsContacts = rhs.contacts.map { EqualContactData(uid: $0.uid, timestamp: $0.modifiedAt) }

        let lhsDeleted = lhs.deleted.map { EqualContactData(uid: $0.uid, timestamp: $0.deletedAt) }
        let rhsDeleted = rhs.deleted.map { EqualContactData(uid: $0.uid, timestamp: $0.deletedAt) }

        return Set(lhsContacts) == Set(rhsContacts) && Set(lhsDeleted) == Set(rhsDeleted)
    }
}

extension ContactBookHelper {
    func insert(contacts: [BackupContact], book: ContactBook?) -> ContactBook {
        var updatedContacts = book?.contacts ?? []

        for contact in contacts {
            var name = contact.name
            if let index = updatedContacts.firstIndex(where: { $0.name == contact.name }) {
                if updatedContacts[index].addresses == contact.addresses {
                    continue
                }

                name = RestoreFileHelper.resolve(
                    name: contact.name,
                    elements: updatedContacts.map { $0.name },
                    style: "(%d)"
                )
            }
            updatedContacts.append(
                Contact(
                    uid: UUID().uuidString,
                    modifiedAt: Date().timeIntervalSince1970,
                    name: name,
                    addresses: contact.addresses
                )
            )
        }

        return ContactBook(
                version: (book?.version ?? 0) + 1,
                contacts: updatedContacts,
                deletedContacts: book?.deleted ?? []
        )
    }

    func update(contact: Contact, book: ContactBook) -> ContactBook {
        var contacts = book.contacts

        if let index = contacts.firstIndex(of: contact) {
            contacts[index] = contact
        } else {
            contacts.append(contact)
        }

        return ContactBook(version: book.version, contacts: contacts, deletedContacts: book.deleted)
    }

    func remove(contactUid: String, book: ContactBook) -> ContactBook {
        if let index = book.contacts.firstIndex(where: { $0.uid == contactUid }) {
            var contacts = book.contacts
            let removed = contacts.remove(at: index)

            var deleted = book.deleted
            deleted.append(DeletedContact(uid: removed.uid, deletedAt: Date().timeIntervalSince1970))

            return ContactBook(version: book.version, contacts: contacts, deletedContacts: deleted)
        }

        return book
    }

    // try resolve contact book. If one of them not changed - return it, else return new one
    func resolved(lhs: ContactBook, rhs: ContactBook) -> ResolveResult {
        if lhs.version > rhs.version {
            return .left
        }
        if lhs.version < rhs.version {
            return .right
        }

        let contacts = mergeNewer(lhs: lhs.contacts, rhs: rhs.contacts)
        let deleted = mergeNewer(lhs: lhs.deleted, rhs: rhs.deleted)

        let resolved = filter(contacts: contacts, deleted: deleted)
        let newBook = ContactBook(version: lhs.version, contacts: resolved.newContacts, deletedContacts: resolved.newDeleted)

        let likeLhs = identical(lhs: lhs, rhs: newBook)
        let likeRhs = identical(lhs: rhs, rhs: newBook)

        if likeLhs && likeRhs {
            return .equal
        }

        if likeLhs {
            return .left
        }

        if likeRhs {
            return .right
        }

        return .merged(newBook)
    }

    func backupContactBook(contactBook: ContactBook) -> BackupContactBook {
        BackupContactBook(
            contacts: contactBook
                .contacts
                .map { BackupContact(uid: $0.uid, name: $0.name, addresses: $0.addresses) }
        )
    }

    func contactBook(contacts: [BackupContact], lastVersion: Int?) -> ContactBook {
        // we need increase version and create new book with latest timestamps for all contacts
        ContactBook(
            version: (lastVersion ?? 0) + 1,
            contacts: contacts
                .map { Contact(uid: $0.uid,
                               modifiedAt: Date().timeIntervalSince1970,
                               name: $0.name,
                               addresses: $0.addresses)
                },
            deletedContacts: []
        )
    }
}

extension ContactBookHelper {
    private struct EqualContactData: Equatable, Hashable {
        let uid: String
        let timestamp: TimeInterval

        static func == (lhs: EqualContactData, rhs: EqualContactData) -> Bool {
            lhs.uid == rhs.uid && lhs.timestamp == rhs.timestamp
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(uid)
            hasher.combine(timestamp)
        }
    }

    enum ResolveResult {
        case equal
        case left
        case right
        case merged(ContactBook)
    }
}
