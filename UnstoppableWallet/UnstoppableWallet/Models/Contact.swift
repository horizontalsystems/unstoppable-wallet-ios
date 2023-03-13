import Foundation
import ObjectMapper

class ContactAddress: ImmutableMappable, Hashable, Equatable {
    let blockchainUid: String
    let address: String

    init(blockchainUid: String, address: String) {
        self.blockchainUid = blockchainUid
        self.address = address
    }

    required init(map: Map) throws {
        blockchainUid = try map.value("blockchain_uid")
        address = try map.value("address")
    }

    func mapping(map: Map) {
        blockchainUid >>> map["blockchain_uid"]
        address       >>> map["address"]
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainUid)
        hasher.combine(address)
    }

    static func ==(lhs: ContactAddress, rhs: ContactAddress) -> Bool {
        lhs.address == rhs.address &&
        lhs.blockchainUid == rhs.blockchainUid
    }

}

extension Array where Element == ContactAddress {

    static func ==(lhs: [ContactAddress], rhs: [ContactAddress]) -> Bool {
        Set(lhs) == Set(rhs)
    }

}

class Contact: ImmutableMappable, Hashable, Equatable {
    let uid: String
    let modifiedAt: TimeInterval
    let name: String
    let addresses: [ContactAddress]

    init(uid: String, modifiedAt: TimeInterval, name: String, addresses: [ContactAddress]) {
        self.uid = uid
        self.modifiedAt = modifiedAt
        self.name = name
        self.addresses = addresses
    }

    required init(map: Map) throws {
        uid = try map.value("uid")
        modifiedAt = try map.value("modified_at")
        name = try map.value("name")
        addresses = try map.value("addresses")
    }

    func mapping(map: Map) {
        uid         >>> map["uid"]
        modifiedAt  >>> map["modified_at"]
        name        >>> map["name"]
        addresses   >>> map["addresses"]
    }

    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        lhs.uid == rhs.uid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

}

class DeletedContact: ImmutableMappable, Hashable, Equatable {
    let uid: String
    let deletedAt: TimeInterval

    init(uid: String, deletedAt: TimeInterval) {
        self.uid = uid
        self.deletedAt = deletedAt
    }

    required init(map: Map) throws {
        uid = try map.value("uid")
        deletedAt = try map.value("deleted_at")
    }

    func mapping(map: Map) {
        uid            >>> map["uid"]
        deletedAt      >>> map["deleted_at"]
    }

    static func ==(lhs: DeletedContact, rhs: DeletedContact) -> Bool {
        lhs.uid == rhs.uid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

}

class ContactBook: ImmutableMappable {
    static let empty = ContactBook(contacts: [], deletedContacts: [])
    let contacts: [Contact]
    let deleted: [DeletedContact]

    init(contacts: [Contact], deletedContacts: [DeletedContact]) {
        self.contacts = contacts
        self.deleted = deletedContacts
    }

    required init(map: Map) throws {
        contacts = try map.value("contacts")
        deleted = try map.value("deleted")
    }

    func mapping(map: Map) {
        contacts        >>> map["contacts"]
        deleted         >>> map["deleted"]
    }

}
