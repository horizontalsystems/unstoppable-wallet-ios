import Testing
import TronKit
@testable import Unstoppable

struct GasFreeProfileMappingTests {
    @Test func recordToDomainAndBackPreservesAllFields() throws {
        let original = GasFreeProfileRecord(
            accountId: "account-1",
            controllerAddress: "TLFXfejEMgivFDR2x8qBpukMXd56spmFhz",
            gasFreeAddress: "TYKTmMyTeAFrfdRTpYHjnAtFEJtMMotJJe",
            providerId: "TLntW9Z59LYY5KEi9cmwk3PKjQga828ird",
            verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U",
            implementationVersion: "gasfree_v1_0_0",
            createdAt: 1_700_000_000,
            lastVerifiedAt: 1_700_000_010
        )

        let domain = try GasFreeProfile(record: original)
        let roundTripped = domain.toRecord()

        #expect(roundTripped.accountId == original.accountId)
        #expect(roundTripped.controllerAddress == original.controllerAddress)
        #expect(roundTripped.gasFreeAddress == original.gasFreeAddress)
        #expect(roundTripped.providerId == original.providerId)
        #expect(roundTripped.verifyingContract == original.verifyingContract)
        #expect(roundTripped.implementationVersion == original.implementationVersion)
        #expect(roundTripped.createdAt == original.createdAt)
        #expect(roundTripped.lastVerifiedAt == original.lastVerifiedAt)
    }

    @Test func nilLastVerifiedAtRoundTrips() throws {
        let original = GasFreeProfileRecord(
            accountId: "account-2",
            controllerAddress: "TLFXfejEMgivFDR2x8qBpukMXd56spmFhz",
            gasFreeAddress: "TYKTmMyTeAFrfdRTpYHjnAtFEJtMMotJJe",
            providerId: "TLntW9Z59LYY5KEi9cmwk3PKjQga828ird",
            verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U",
            implementationVersion: "gasfree_v1_0_0",
            createdAt: 1_700_000_000,
            lastVerifiedAt: nil
        )

        let domain = try GasFreeProfile(record: original)
        let roundTripped = domain.toRecord()

        #expect(roundTripped.lastVerifiedAt == nil)
    }

    @Test func malformedControllerAddressThrows() {
        let record = GasFreeProfileRecord(
            accountId: "account-3",
            controllerAddress: "not-a-tron-address",
            gasFreeAddress: "TYKTmMyTeAFrfdRTpYHjnAtFEJtMMotJJe",
            providerId: "TLntW9Z59LYY5KEi9cmwk3PKjQga828ird",
            verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U",
            implementationVersion: "gasfree_v1_0_0",
            createdAt: 0,
            lastVerifiedAt: nil
        )

        #expect(throws: GasFreeProfile.ConversionError.invalidAddress(field: "controllerAddress")) {
            try GasFreeProfile(record: record)
        }
    }

    @Test func malformedGasFreeAddressThrows() {
        let record = GasFreeProfileRecord(
            accountId: "account-4",
            controllerAddress: "TLFXfejEMgivFDR2x8qBpukMXd56spmFhz",
            gasFreeAddress: "garbage",
            providerId: "TLntW9Z59LYY5KEi9cmwk3PKjQga828ird",
            verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U",
            implementationVersion: "gasfree_v1_0_0",
            createdAt: 0,
            lastVerifiedAt: nil
        )

        #expect(throws: GasFreeProfile.ConversionError.invalidAddress(field: "gasFreeAddress")) {
            try GasFreeProfile(record: record)
        }
    }
}
