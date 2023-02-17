import Foundation
import ObjectMapper

class ContactAddress: ImmutableMappable {
    let blockchainUid: String
    let address: String

    init(blockhainUid: String, address: String) {
        self.blockchainUid = blockhainUid
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
    let name: String
    let addresses: [ContactAddress]

    init(name: String, addresses: [ContactAddress]) {
        self.name = name
        self.addresses = addresses
    }

    required init(map: Map) throws {
        name = try map.value("name")
        addresses = try map.value("addresses")
    }

    func mapping(map: Map) {
        name      >>> map["name"]
        addresses >>> map["addresses"]
    }

    static func ==(lhs: Contact, rhs: Contact) -> Bool {
        lhs.name == rhs.name
    }

}

class ContactBook: ImmutableMappable {
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
