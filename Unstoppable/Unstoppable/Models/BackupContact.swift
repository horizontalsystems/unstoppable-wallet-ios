import Foundation
import ObjectMapper

class BackupContact: Codable, ImmutableMappable, Hashable, Equatable {
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
        uid >>> map["uid"]
        name >>> map["name"]
        addresses >>> map["addresses"]
    }

    static func == (lhs: BackupContact, rhs: BackupContact) -> Bool {
        lhs.uid == rhs.uid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }

    func address(blockchainUid: String) -> ContactAddress? {
        addresses.first { $0.blockchainUid == blockchainUid }
    }
}

class BackupContactBook: Codable {
    static let empty = BackupContactBook(contacts: [])
    let contacts: [BackupContact]

    init(contacts: [BackupContact]) {
        self.contacts = contacts
    }
}
