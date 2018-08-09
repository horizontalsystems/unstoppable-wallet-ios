import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionLinkerTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var linker: TransactionLinker!

    private var realm: Realm!
    private var transaction: Transaction!
    private var addresses: [Address]!
    private var pubKeyHash = Data(hex: "1ec865abcb88cec71c484d4dadec3d7dc0271a7b")!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        linker = TransactionLinker(realmFactory: mockRealmFactory)
        transaction = TestData.p2pkhTransaction

        try! realm.write {
            realm.add(TestData.address(pubKeyHash: pubKeyHash), update: true)
            realm.add(transaction)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        linker = nil
        realm = nil

        super.tearDown()
    }

    func testLinkOutputs() {
        let input = TransactionInput()
        input.previousOutputTxReversedHex = Data(hex: transaction.reversedHashHex)!
        input.previousOutputIndex = transaction.outputs.first!.index
        input.sequence = 100

        let savedNextTransaction = Transaction()
        savedNextTransaction.reversedHashHex = "0000000000000000000111111111111122222222222222333333333333333000"
        savedNextTransaction.inputs.append(input)

        try! realm.write {
            realm.add(transaction, update: true)
            realm.add(savedNextTransaction, update: true)
        }

        XCTAssertEqual(savedNextTransaction.inputs.first!.previousOutput, nil)
        try! linker.handle(transaction: savedNextTransaction)
        assertOutputEqual(out1: savedNextTransaction.inputs.first!.previousOutput!, out2: transaction.outputs.first!)
    }

    func testLinkInputs() {
        let output = TransactionOutput()
        output.index = transaction.inputs[0].previousOutputIndex
        output.value = 100000

        let savedPreviousTransaction = Transaction()
        savedPreviousTransaction.reversedHashHex = transaction.inputs[0].previousOutputTxReversedHex.hex
        savedPreviousTransaction.outputs.append(output)

        try! realm.write {
            realm.add(transaction, update: true)
            realm.add(savedPreviousTransaction, update: true)
        }

        XCTAssertEqual(transaction.inputs.first!.previousOutput, nil)
        try! linker.handle(transaction: savedPreviousTransaction)
        assertOutputEqual(out1: transaction.inputs.first!.previousOutput!, out2: savedPreviousTransaction.outputs.first!)
    }

    func testSetTransactionAndOutputIsMine() {
        try! realm.write {
            transaction.outputs[0].scriptType = ScriptType.p2pkh
            transaction.outputs[0].keyHash = pubKeyHash
        }

        XCTAssertEqual(transaction.isMine, false)
        XCTAssertEqual(transaction.outputs[0].isMine, false)
        try! linker.handle(transaction: transaction)
        XCTAssertEqual(transaction.isMine, true)
        XCTAssertEqual(transaction.outputs[0].isMine, true)
    }

    func testSetNextTransactionIsMine() {
        let input = TransactionInput()
        input.previousOutputTxReversedHex = Data(hex: transaction.reversedHashHex)!
        input.previousOutputIndex = transaction.outputs.first!.index
        input.sequence = 100

        let savedNextTransaction = Transaction()
        savedNextTransaction.reversedHashHex = "0000000000000000000111111111111122222222222222333333333333333000"
        savedNextTransaction.inputs.append(input)

        try! realm.write {
            realm.add(savedNextTransaction, update: true)
            transaction.outputs[0].scriptType = ScriptType.p2pkh
            transaction.outputs[0].keyHash = pubKeyHash
        }

        XCTAssertEqual(savedNextTransaction.isMine, false)
        try! linker.handle(transaction: transaction)
        XCTAssertEqual(savedNextTransaction.isMine, true)
    }

    func testSetPreviousTransactionIsMine() {
        let output = TransactionOutput()
        output.index = transaction.inputs[0].previousOutputIndex
        output.value = 100000
        output.isMine = true

        let savedPreviousTransaction = Transaction()
        savedPreviousTransaction.reversedHashHex = transaction.inputs[0].previousOutputTxReversedHex.hex
        savedPreviousTransaction.outputs.append(output)

        try! realm.write {
            realm.add(transaction, update: true)
            realm.add(savedPreviousTransaction, update: true)
        }

        XCTAssertEqual(transaction.isMine, false)
        try! linker.handle(transaction: transaction)
        XCTAssertEqual(transaction.isMine, true)
    }

    private func assertOutputEqual(out1: TransactionOutput, out2: TransactionOutput) {
        XCTAssertEqual(out1.value, out2.value)
        XCTAssertEqual(out1.lockingScript, out2.lockingScript)
        XCTAssertEqual(out1.index, out2.index)
    }

}
