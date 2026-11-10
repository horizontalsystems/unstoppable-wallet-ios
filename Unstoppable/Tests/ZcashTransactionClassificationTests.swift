import Testing
@testable import WalletCore
import ZODLSwiftWalletSDK

/// How a Zcash transaction lands in history when this wallet did not create it: a payment or a migration made on another
/// device with the same seed, or by the owner of a watched viewing key.
struct ZcashTransactionClassificationTests {
    // MARK: unshield

    @Test func moveBetweenOwnPoolsIsAnUnshield() {
        // 1 ZEC from shielded to the account's own transparent address: the account loses only the fee
        #expect(internalTransfer(spent: 100_000_000, received: 99_990_000, fee: 10000))
    }

    @Test func paymentWithUndecryptedRecipientStaysAPayment() {
        // 0.7 ZEC paid out of a 1 ZEC note; only the 0.29 change is in sight, so every known recipient is internal
        #expect(!internalTransfer(spent: 100_000_000, received: 29_990_000, fee: 10000))
    }

    @Test func unknownFeeIsNotAnUnshield() {
        #expect(!ZcashTransactionWrapper.isInternalTransfer(
            isSentTransaction: true,
            value: Zatoshi(-10000),
            fee: nil,
            totalSpent: Zatoshi(100_000_000),
            totalReceived: Zatoshi(99_990_000),
            recipientsAllInternal: true
        ))
    }

    @Test func externalRecipientIsNotAnUnshield() {
        #expect(!internalTransfer(spent: 100_000_000, received: 99_990_000, fee: 10000, recipientsAllInternal: false))
    }

    @Test func receiveIsNotAnUnshield() {
        #expect(!ZcashTransactionWrapper.isInternalTransfer(
            isSentTransaction: false,
            value: Zatoshi(50000),
            fee: Zatoshi(10000),
            totalSpent: Zatoshi(0),
            totalReceived: Zatoshi(50000),
            recipientsAllInternal: true
        ))
    }

    // MARK: migration

    @Test func onlyPreparationAndTransferAreMigrations() {
        #expect(ZcashTransactionWrapper.isMigration(kind: .preparation))
        #expect(ZcashTransactionWrapper.isMigration(kind: .transfer))
        #expect(!ZcashTransactionWrapper.isMigration(kind: .nonconforming))
        #expect(!ZcashTransactionWrapper.isMigration(kind: .notClassified))
    }

    private func internalTransfer(spent: Int64, received: Int64, fee: Int64, recipientsAllInternal: Bool = true) -> Bool {
        ZcashTransactionWrapper.isInternalTransfer(
            isSentTransaction: true,
            value: Zatoshi(received - spent),
            fee: Zatoshi(fee),
            totalSpent: Zatoshi(spent),
            totalReceived: Zatoshi(received),
            recipientsAllInternal: recipientsAllInternal
        )
    }
}
