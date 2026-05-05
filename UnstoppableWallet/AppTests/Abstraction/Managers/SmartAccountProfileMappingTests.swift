import BigInt
import EvmKit
import Foundation
import MarketKit
import Testing
@testable import Unstoppable

struct SmartAccountProfileMappingTests {
    @Test func profileRoundTripThroughRecord() throws {
        let original = SmartAccountProfile(
            id: "profile-1",
            accountId: "account-1",
            implementationVersion: "barz_v1_0_0",
            ownerPublicKeyX: Data(repeating: 0x11, count: 32),
            ownerPublicKeyY: Data(repeating: 0x22, count: 32),
            curve: .secp256r1,
            salt: 0,
            createdAt: 1_700_000_000
        )

        let record = original.toRecord()
        let restored = try SmartAccountProfile(record: record)

        #expect(restored == original)
    }

    @Test func deploymentRoundTripThroughRecord() throws {
        let original = SmartAccountDeployment(
            id: "deployment-1",
            profileId: "profile-1",
            blockchainType: .ethereum,
            implementationVersion: "barz_v1_0_0",
            isDeployed: true,
            preferredPaymaster: "pimlico",
            activatedAt: 1_700_000_000
        )

        let record = original.toRecord()
        let restored = SmartAccountDeployment(record: record)

        #expect(restored == original)
    }

    @Test func invalidCurveInRecordThrows() {
        let record = SmartAccountProfileRecord(
            id: "profile-1",
            accountId: "account-1",
            implementationVersion: "barz_v1_0_0",
            ownerPublicKeyX: String(repeating: "11", count: 32),
            ownerPublicKeyY: String(repeating: "22", count: 32),
            curve: "not-a-curve",
            salt: "0",
            createdAt: 1_700_000_000
        )

        #expect(throws: SmartAccountProfile.ConversionError.invalidCurve(field: "curve")) {
            _ = try SmartAccountProfile(record: record)
        }
    }

    @Test func invalidPubkeyHexInRecordThrows() {
        let record = SmartAccountProfileRecord(
            id: "profile-1",
            accountId: "account-1",
            implementationVersion: "barz_v1_0_0",
            ownerPublicKeyX: "not-hex",
            ownerPublicKeyY: String(repeating: "22", count: 32),
            curve: "secp256r1",
            salt: "0",
            createdAt: 1_700_000_000
        )

        #expect(throws: SmartAccountProfile.ConversionError.invalidHex(field: "ownerPublicKeyX")) {
            _ = try SmartAccountProfile(record: record)
        }
    }

    @Test func invalidSaltInRecordThrows() {
        let record = SmartAccountProfileRecord(
            id: "profile-1",
            accountId: "account-1",
            implementationVersion: "barz_v1_0_0",
            ownerPublicKeyX: String(repeating: "11", count: 32),
            ownerPublicKeyY: String(repeating: "22", count: 32),
            curve: "secp256r1",
            salt: "not-a-number",
            createdAt: 1_700_000_000
        )

        #expect(throws: SmartAccountProfile.ConversionError.invalidBigUInt(field: "salt")) {
            _ = try SmartAccountProfile(record: record)
        }
    }
}
