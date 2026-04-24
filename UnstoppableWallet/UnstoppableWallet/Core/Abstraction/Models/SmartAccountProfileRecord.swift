import Foundation
import GRDB

class SmartAccountProfileRecord: Record {
    let id: String
    let accountId: String
    let address: String
    let implementationVersion: String
    let ownerPublicKeyX: String
    let ownerPublicKeyY: String
    let salt: String
    let createdAt: TimeInterval

    init(
        id: String,
        accountId: String,
        address: String,
        implementationVersion: String,
        ownerPublicKeyX: String,
        ownerPublicKeyY: String,
        salt: String,
        createdAt: TimeInterval
    ) {
        self.id = id
        self.accountId = accountId
        self.address = address
        self.implementationVersion = implementationVersion
        self.ownerPublicKeyX = ownerPublicKeyX
        self.ownerPublicKeyY = ownerPublicKeyY
        self.salt = salt
        self.createdAt = createdAt

        super.init()
    }

    override class var databaseTableName: String {
        "smart_account_profiles"
    }

    enum Columns: String, ColumnExpression {
        case id, accountId, address, implementationVersion,
             ownerPublicKeyX, ownerPublicKeyY, salt, createdAt
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        accountId = row[Columns.accountId]
        address = row[Columns.address]
        implementationVersion = row[Columns.implementationVersion]
        ownerPublicKeyX = row[Columns.ownerPublicKeyX]
        ownerPublicKeyY = row[Columns.ownerPublicKeyY]
        salt = row[Columns.salt]
        createdAt = row[Columns.createdAt]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.accountId] = accountId
        container[Columns.address] = address
        container[Columns.implementationVersion] = implementationVersion
        container[Columns.ownerPublicKeyX] = ownerPublicKeyX
        container[Columns.ownerPublicKeyY] = ownerPublicKeyY
        container[Columns.salt] = salt
        container[Columns.createdAt] = createdAt
    }
}
