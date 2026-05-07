import Foundation
import MarketKit

struct SmartAccountDeployment: Equatable, Hashable {
    let id: String
    let profileId: String
    let blockchainType: BlockchainType
    let implementationVersion: String
    let isDeployed: Bool
    let preferredPaymaster: String
    let activatedAt: TimeInterval
}

extension SmartAccountDeployment {
    init(record: SmartAccountDeploymentRecord) {
        self.init(
            id: record.id,
            profileId: record.profileId,
            blockchainType: BlockchainType(uid: record.blockchainType),
            implementationVersion: record.implementationVersion,
            isDeployed: record.isDeployed,
            preferredPaymaster: record.preferredPaymaster,
            activatedAt: record.activatedAt
        )
    }

    func toRecord() -> SmartAccountDeploymentRecord {
        SmartAccountDeploymentRecord(
            id: id,
            profileId: profileId,
            blockchainType: blockchainType.uid,
            implementationVersion: implementationVersion,
            isDeployed: isDeployed,
            preferredPaymaster: preferredPaymaster,
            activatedAt: activatedAt
        )
    }
}
