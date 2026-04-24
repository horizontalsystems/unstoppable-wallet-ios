import Foundation
import GRDB

class SmartAccountDeploymentRecord: Record {
    let id: String
    let profileId: String
    let blockchainType: String
    let implementationVersion: String
    let isDeployed: Bool
    let preferredPaymaster: String
    let activatedAt: TimeInterval

    init(
        id: String,
        profileId: String,
        blockchainType: String,
        implementationVersion: String,
        isDeployed: Bool,
        preferredPaymaster: String,
        activatedAt: TimeInterval
    ) {
        self.id = id
        self.profileId = profileId
        self.blockchainType = blockchainType
        self.implementationVersion = implementationVersion
        self.isDeployed = isDeployed
        self.preferredPaymaster = preferredPaymaster
        self.activatedAt = activatedAt

        super.init()
    }

    override class var databaseTableName: String {
        "smart_account_deployments"
    }

    enum Columns: String, ColumnExpression {
        case id, profileId, blockchainType, implementationVersion,
             isDeployed, preferredPaymaster, activatedAt
    }

    required init(row: Row) throws {
        id = row[Columns.id]
        profileId = row[Columns.profileId]
        blockchainType = row[Columns.blockchainType]
        implementationVersion = row[Columns.implementationVersion]
        isDeployed = row[Columns.isDeployed]
        preferredPaymaster = row[Columns.preferredPaymaster]
        activatedAt = row[Columns.activatedAt]

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.profileId] = profileId
        container[Columns.blockchainType] = blockchainType
        container[Columns.implementationVersion] = implementationVersion
        container[Columns.isDeployed] = isDeployed
        container[Columns.preferredPaymaster] = preferredPaymaster
        container[Columns.activatedAt] = activatedAt
    }
}
