import Foundation
import ObjectMapper

class ContactAddress: Codable, ImmutableMappable, Hashable, Equatable {
    let blockchainUid: String
    let address: String

    enum CodingKeys: String, CodingKey {
        case blockchainUid = "blockchain_uid"
        case address
    }

    init(blockchainUid: String, address: String) {
        self.blockchainUid = blockchainUid
        self.address = address
    }

    required init(map: Map) throws {
        blockchainUid = try map.value(CodingKeys.blockchainUid.rawValue)
        address = try map.value(CodingKeys.address.rawValue)
    }

    func mapping(map: Map) {
        blockchainUid >>> map[CodingKeys.blockchainUid.rawValue]
        address >>> map[CodingKeys.address.rawValue]
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockchainUid)
        hasher.combine(address.lowercased())
    }

    static func == (lhs: ContactAddress, rhs: ContactAddress) -> Bool {
        lhs.address.lowercased() == rhs.address.lowercased() &&
            lhs.blockchainUid == rhs.blockchainUid
    }
}

extension Array where Element == ContactAddress {
    static func == (lhs: [ContactAddress], rhs: [ContactAddress]) -> Bool {
        Set(lhs) == Set(rhs)
    }
}

class Contact: Codable, ImmutableMappable, Hashable, Equatable {
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
        uid >>> map["uid"]
        modifiedAt >>> map["modified_at"]
        name >>> map["name"]
        addresses >>> map["addresses"]
    }

    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.uid == rhs.uid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

    func address(blockchainUid: String) -> ContactAddress? {
        addresses.first { $0.blockchainUid == blockchainUid }
    }
}

class DeletedContact: Codable, ImmutableMappable, Hashable, Equatable {
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
        uid >>> map["uid"]
        deletedAt >>> map["deleted_at"]
    }

    static func == (lhs: DeletedContact, rhs: DeletedContact) -> Bool {
        lhs.uid == rhs.uid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
}

class ContactBook: Codable, ImmutableMappable {
    static let empty = ContactBook(contacts: [], deletedContacts: [])
    let version: Int
    let contacts: [Contact]
    let deleted: [DeletedContact]

    init(version: Int? = nil, contacts: [Contact], deletedContacts: [DeletedContact]) {
        self.version = version ?? 0
        self.contacts = contacts
        deleted = deletedContacts
    }

    required init(map: Map) throws {
        version = (try? map.value("version")) ?? 0
        contacts = try map.value("contacts")
        deleted = try map.value("deleted")
    }

    func mapping(map: Map) {
        version >>> map["version"]
        contacts >>> map["contacts"]
        deleted >>> map["deleted"]
    }
}
