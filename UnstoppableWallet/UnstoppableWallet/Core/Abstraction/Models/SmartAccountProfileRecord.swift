import Foundation
import GRDB

class SmartAccountProfileRecord: Record {
    let id: String
    let accountId: String
    let implementationVersion: String
    let ownerPublicKeyX: String
    let ownerPublicKeyY: String
    let curve: String
    let salt: String
    let createdAt: TimeInterval

    init(
        id: String,
        accountId: String,
        implementationVersion: String,
        ownerPublicKeyX: String,
        ownerPublicKeyY: String,
        curve: String,
        salt: String,
        createdAt: TimeInterval
    ) {
        self.id = id
        self.accountId = accountId
        self.implementationVersion = implementationVersion
        self.ownerPublicKeyX = ownerPublicKeyX
        self.ownerPublicKeyY = ownerPublicKeyY
        self.curve = curve
        self.salt = salt
        self.createdAt = createdAt

        super.init()
    }

    override class var databaseTableName: String {
        "account_abstraction_profiles"
    }

    enum Columns: String, ColumnExpression {
        case id, accountId, implementationVersion,
             ownerPublicKeyX, ownerPublicKeyY, curve, salt, createdAt
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        accountId = row[Columns.accountId]
        implementationVersion = row[Columns.implementationVersion]
        ownerPublicKeyX = row[Columns.ownerPublicKeyX]
        ownerPublicKeyY = row[Columns.ownerPublicKeyY]
        curve = row[Columns.curve]
        salt = row[Columns.salt]
        createdAt = row[Columns.createdAt]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.accountId] = accountId
        container[Columns.implementationVersion] = implementationVersion
        container[Columns.ownerPublicKeyX] = ownerPublicKeyX
        container[Columns.ownerPublicKeyY] = ownerPublicKeyY
        container[Columns.curve] = curve
        container[Columns.salt] = salt
        container[Columns.createdAt] = createdAt
    }
}

class GasFreeProfileRecord: Record {
    let accountId: String
    let controllerAddress: String
    let gasFreeAddress: String
    let providerId: String
    let verifyingContract: String
    let createdAt: TimeInterval
    let lastVerifiedAt: TimeInterval?

    init(
        accountId: String,
        controllerAddress: String,
        gasFreeAddress: String,
        providerId: String,
        verifyingContract: String,
        createdAt: TimeInterval,
        lastVerifiedAt: TimeInterval?
    ) {
        self.accountId = accountId
        self.controllerAddress = controllerAddress
        self.gasFreeAddress = gasFreeAddress
        self.providerId = providerId
        self.verifyingContract = verifyingContract
        self.createdAt = createdAt
        self.lastVerifiedAt = lastVerifiedAt

        super.init()
    }

    override class var databaseTableName: String {
        "gas_free_profiles"
    }

    enum Columns: String, ColumnExpression {
        case accountId, controllerAddress, gasFreeAddress, providerId, verifyingContract, createdAt, lastVerifiedAt
    }

    required init(row: Row) throws {
        accountId = row[Columns.accountId]
        controllerAddress = row[Columns.controllerAddress]
        gasFreeAddress = row[Columns.gasFreeAddress]
        providerId = row[Columns.providerId]
        verifyingContract = row[Columns.verifyingContract]
        createdAt = row[Columns.createdAt]
        lastVerifiedAt = row[Columns.lastVerifiedAt]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.accountId] = accountId
        container[Columns.controllerAddress] = controllerAddress
        container[Columns.gasFreeAddress] = gasFreeAddress
        container[Columns.providerId] = providerId
        container[Columns.verifyingContract] = verifyingContract
        container[Columns.createdAt] = createdAt
        container[Columns.lastVerifiedAt] = lastVerifiedAt
    }
}
