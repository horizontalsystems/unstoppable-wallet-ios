import Foundation
import ObjectMapper

class ContactAddress: ImmutableMappable {
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

}

class Contact: ImmutableMappable, Equatable {
    let uid: String
    let name: String
    let addresses: [ContactAddress]

    init(uid: String, name: String, addresses: [ContactAddress]) {
        self.uid = uid
        self.name = name
        self.addresses = addresses
    }

    required init(map: Map) throws {
        uid = try map.value("uid")
        name = try map.value("name")
        addresses = try map.value("addresses")
    }

    func mapping(map: Map) {
        uid      >>> map["uid"]
        name      >>> map["name"]
        addresses >>> map["addresses"]
    }

    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        lhs.uid == rhs.uid
    }

}

class ContactBook: ImmutableMappable {
    static let empty = ContactBook(timestamp: .zero, contacts: [])
    let timestamp: TimeInterval
    let contacts: [Contact]

    init(timestamp: TimeInterval, contacts: [Contact]) {
        self.timestamp = timestamp
        self.contacts = contacts
    }

    required init(map: Map) throws {
        timestamp = try map.value("timestamp")
        contacts = try map.value("contacts")
    }

    func mapping(map: Map) {
        timestamp >>> map["timestamp"]
        contacts  >>> map["contacts"]
    }

}
