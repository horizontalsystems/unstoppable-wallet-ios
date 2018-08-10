import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionBuilderTests: XCTestCase{

    private var realm: Realm!
    private var mockRealmFactory: MockRealmFactory!
    private var mockUnspentOutputsManager: MockUnspentOutputsManager!
    private var mockInputSigner: MockInputSigner!
    private var mockScriptBuilder:  MockScriptBuilder!
    private var mockTxFactory: MockTransactionFactory!

    private var transactionBuilder: TransactionBuilder!

    private var unspentOutputs: [TransactionOutput]!
    private var transaction: Transaction!
    private var toOutput: TransactionOutput!
    private var changeOutput: TransactionOutput!
    private var input: TransactionInput!
    private var totalInputValue: Int!
    private var value: Int!
    private var feeRate: Int!
    private var fee: Int!
    private var changeAddress: Address!
    private var toAddress: Address!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write {
            realm.deleteAll()
        }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        mockUnspentOutputsManager = MockUnspentOutputsManager(realmFactory: mockRealmFactory)
        mockInputSigner = MockInputSigner(realmFactory: mockRealmFactory)
        mockScriptBuilder = MockScriptBuilder()
        mockTxFactory = MockTransactionFactory()

        transactionBuilder = TransactionBuilder(unspentOutputsManager: mockUnspentOutputsManager, inputSigner: mockInputSigner, scriptBuilder: mockScriptBuilder, txFactory: mockTxFactory)

        changeAddress = TestData.address()
        toAddress = TestData.address(pubKeyHash: Data(hex: "64d8fbe748c577bb5da29718dae0402b0b5dd523")!)

        let previousTransaction = TestData.p2pkhTransaction
        try! realm.write {
            realm.add(previousTransaction, update: true)
        }

        unspentOutputs = [previousTransaction.outputs[0]]
        totalInputValue = unspentOutputs[0].value
        value = 10782000
        feeRate = 6
        fee = 1158

        transaction = TransactionFactory().transaction(version: 1, inputs: [], outputs: [])
        input = TransactionFactory().transactionInput(withPreviousOutput: unspentOutputs[0], script: Data(), sequence: 0)
        toOutput = try? TransactionFactory().transactionOutput(withValue: value - fee, withLockingScript: Data(), withIndex: 0, type: .p2pkh, keyHash: toAddress.publicKeyHash)
        changeOutput = try? TransactionFactory().transactionOutput(withValue: totalInputValue - value, withLockingScript: Data(), withIndex: 1, type: .p2pkh, keyHash: changeAddress.publicKeyHash)

        stub(mockUnspentOutputsManager) { mock in
            when(mock.select(value: any(), outputs: any())).thenReturn(unspentOutputs)
        }

        stub(mockInputSigner) { mock in
            when(mock.sigScriptData(input: any(), transaction: any(), index: any())).thenReturn([Data()])
        }

        stub(mockTxFactory) { mock in
            when(mock.transaction(version: any(), inputs: any(), outputs: any(), lockTime: any())).thenReturn(transaction)
        }

        stub(mockTxFactory) { mock in
            when(mock.transactionInput(withPreviousOutput: any(), script: any(), sequence: any())).thenReturn(input)
        }

        stub(mockTxFactory) { mock in
            when(mock.transactionOutput(withValue: any(), withLockingScript: any(), withIndex: any(), type: equal(to: ScriptType.p2pkh), keyHash: equal(to: toAddress.publicKeyHash))).thenReturn(toOutput)
            when(mock.transactionOutput(withValue: any(), withLockingScript: any(), withIndex: any(), type: equal(to: ScriptType.p2pkh), keyHash: equal(to: changeAddress.publicKeyHash))).thenReturn(changeOutput)
        }
    }

    override func tearDown() {
        mockRealmFactory = nil
        realm = nil
        unspentOutputs = nil
        mockUnspentOutputsManager = nil
        mockInputSigner = nil
        mockTxFactory = nil
        transactionBuilder = nil
        changeAddress = nil
        toAddress = nil
        value = nil
        feeRate = nil
        fee = nil

        super.tearDown()
    }

    func testBuildTransaction() {
        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 2)
        XCTAssertEqual(resultTx.outputs[0].keyHash, toAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)  // value - fee
        XCTAssertEqual(resultTx.outputs[1].keyHash, changeAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[1].value, unspentOutputs[0].value - value)
    }

    func testWithoutChangeOutput() {
        value = totalInputValue

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].keyHash, toAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }

    func testChangeNotAddedForDust() {
        value = totalInputValue - TransactionBuilder.outputSize * feeRate

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].keyHash, toAddress.publicKeyHash)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }

    func testInputsSigned() {
        let signature = Data(hex: "1214124faf823f23fd2342e234234a23423c23423b4132")!

        stub(mockInputSigner) { mock in
            when(mock.sigScriptData(input: any(), transaction: any(), index: any())).thenReturn([signature])
        }

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, changeAddress: changeAddress, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs[0].signatureScript, signature)
    }

}
