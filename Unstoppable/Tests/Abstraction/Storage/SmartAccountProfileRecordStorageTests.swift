import Foundation
import GRDB
import Testing
@testable import Unstoppable
@testable import WalletCore

struct SmartAccountProfileRecordStorageTests {
    @Test func saveRoundTrip() throws {
        let env = try AaStorageTestEnvironment()
        let original = env.makeProfile()

        try env.profileStorage.save(record: original)

        let fetched = try env.profileStorage.profile(id: original.id)
        let restored = try #require(fetched)

        #expect(restored.id == original.id)
        #expect(restored.accountId == original.accountId)
        #expect(restored.implementationVersion == original.implementationVersion)
        #expect(restored.ownerPublicKeyX == original.ownerPublicKeyX)
        #expect(restored.ownerPublicKeyY == original.ownerPublicKeyY)
        #expect(restored.curve == original.curve)
        #expect(restored.salt == original.salt)
        #expect(restored.createdAt == original.createdAt)
    }

    @Test func lookupByAccountId() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile(accountId: "account-42")

        try env.profileStorage.save(record: profile)

        let found = try env.profileStorage.profile(accountId: "account-42")
        let missing = try env.profileStorage.profile(accountId: "other")

        #expect(found?.id == profile.id)
        #expect(missing == nil)
    }

    @Test func profileByIdReturnsNilWhenMissing() throws {
        let env = try AaStorageTestEnvironment()

        let missing = try env.profileStorage.profile(id: "missing")

        #expect(missing == nil)
    }

    @Test func allReturnsEverySaved() throws {
        let env = try AaStorageTestEnvironment()
        for _ in 0 ..< 3 {
            try env.profileStorage.save(record: env.makeProfile())
        }

        let all = try env.profileStorage.all()

        #expect(all.count == 3)
    }

    @Test func deleteById() throws {
        let env = try AaStorageTestEnvironment()
        let a = env.makeProfile()
        let b = env.makeProfile()
        try env.profileStorage.save(record: a)
        try env.profileStorage.save(record: b)

        try env.profileStorage.delete(id: a.id)

        let deletedA = try env.profileStorage.profile(id: a.id)
        let remainingB = try env.profileStorage.profile(id: b.id)

        #expect(deletedA == nil)
        #expect(remainingB != nil)
    }

    @Test func deleteByAccountId() throws {
        let env = try AaStorageTestEnvironment()
        let profile = env.makeProfile(accountId: "account-7")
        try env.profileStorage.save(record: profile)

        try env.profileStorage.delete(accountId: "account-7")

        let deleted = try env.profileStorage.profile(id: profile.id)

        #expect(deleted == nil)
    }

    @Test func clearRemovesAll() throws {
        let env = try AaStorageTestEnvironment()
        try env.profileStorage.save(record: env.makeProfile())
        try env.profileStorage.save(record: env.makeProfile())

        try env.profileStorage.clear()

        let remaining = try env.profileStorage.all()

        #expect(remaining.isEmpty)
    }

    @Test func duplicateAccountIdThrows() throws {
        let env = try AaStorageTestEnvironment()
        let first = env.makeProfile(accountId: "same-account")
        let second = env.makeProfile(accountId: "same-account")

        try env.profileStorage.save(record: first)

        #expect(throws: (any Error).self) {
            try env.profileStorage.save(record: second)
        }
    }

    @Test func gasFreeProfileSaveRoundTrip() throws {
        let env = try AaStorageTestEnvironment()
        let original = env.makeGasFreeProfile(accountId: "account-gasfree")
        let updated = GasFreeProfileRecord(
            accountId: "account-gasfree",
            controllerAddress: original.controllerAddress,
            gasFreeAddress: "TYw8QmxE9gZ8Uj7PzX9pU7VfFq8M4B9x2p",
            providerId: original.providerId,
            verifyingContract: original.verifyingContract,
            implementationVersion: original.implementationVersion,
            createdAt: original.createdAt,
            lastVerifiedAt: 1_700_000_020
        )

        try env.gasFreeProfileStorage.save(record: original)
        try env.gasFreeProfileStorage.save(record: updated)

        let fetched = try env.gasFreeProfileStorage.profile(accountId: "account-gasfree")
        let restored = try #require(fetched)

        #expect(restored.accountId == updated.accountId)
        #expect(restored.controllerAddress == updated.controllerAddress)
        #expect(restored.gasFreeAddress == updated.gasFreeAddress)
        #expect(restored.providerId == updated.providerId)
        #expect(restored.verifyingContract == updated.verifyingContract)
        #expect(restored.createdAt == updated.createdAt)
        #expect(restored.lastVerifiedAt == updated.lastVerifiedAt)
    }
}
