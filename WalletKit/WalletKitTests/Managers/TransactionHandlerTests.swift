import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionHandlerTests: XCTestCase {
    private var mockRealmFactory: MockRealmFactory!
    private var mockValidator: MockTransactionValidator!
    private var mockSaver: MockTransactionSaver!
    private var transactionHandler: TransactionHandler!

    private var realm: Realm!
    private var transaction: Transaction!
    private var sampleTransactionMessage: TransactionMessage!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        mockValidator = MockTransactionValidator()
        mockSaver = MockTransactionSaver()
        transactionHandler = TransactionHandler(realmFactory: mockRealmFactory, validator: mockValidator, saver: mockSaver)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        transaction = Transaction()
        transaction.reversedHashHex = Data(hex: "3e7f350bf5c2169833ad02e8ada93a5d47862fe708cdd6c9fb4c15af59e50f70")!.reversedHex

        var txInputItem = TransactionInputItem(
                previousOutput: TransactionOutPointItem(hash: Data(hex: "28c004efa76de2dc58921a9eb21fd1a0f5aa91286e7f44e5800ca9d76c105c86")!, index: 0),
                scriptLength: 72,
                signatureScript: Data(hex: "47304402205c54aa165861bf5347683fb078a99188726ee2577e3554d0f77ad7c60a4b072902206f77f42f216e4c64585a60ec76a944fc83278524e5a0dfda31b58f94035d27be01")!,
                sequence: 4294967295
        )

        var txOutputItem = TransactionOutputItem(value: 4998000000, scriptLength: 23, lockingScript: Data(hex: "a914121e63ee09fc7e20b59d144dcce6e2700f6f1a9c87")!)

        sampleTransactionMessage = TransactionMessage(version: 1, txInCount: 1, inputs: [txInputItem], txOutCount: 1, outputs: [txOutputItem], lockTime: 0)

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockSaver) { mock in
            when(mock.update(transaction: any(), withContentsOf: any()).thenDoNothing())
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockValidator = nil
        mockSaver = nil
        transactionHandler = nil

        realm = nil
        transaction = nil

        super.tearDown()
    }

    func testValidTransaction() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleTransactionMessage))).thenDoNothing()
        }

        try! transactionHandler.handle(message: sampleTransactionMessage)
        verify(mockSaver).update(transaction: equal(to: nil), withContentsOf: equal(to: sampleTransactionMessage))
    }

    func testWithExistingTransaction() {
        try? realm.write {
            realm.add([transaction], update: true)
        }

        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleTransactionMessage))).thenDoNothing()
        }

        try! transactionHandler.handle(message: sampleTransactionMessage)
        verify(mockSaver).update(transaction: equal(to: transaction), withContentsOf: equal(to: sampleTransactionMessage))
    }

    func testWithInvalidTransaction() {
        stub(mockValidator) { mock in
            when(mock.validate(message: equal(to: sampleTransactionMessage))).thenThrow(TransactionValidator.ValidationError.doesNotBelongToCurrentWallet)
        }

        try? transactionHandler.handle(message: sampleTransactionMessage)
        verifyNoMoreInteractions(mockSaver)
    }

}
