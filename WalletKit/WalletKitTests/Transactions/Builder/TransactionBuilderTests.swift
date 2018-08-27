import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionBuilderTests: XCTestCase {

    private var realm: Realm!
    private var mockUnspentOutputSelector: MockUnspentOutputSelector!
    private var mockUnspentOutputProvider: MockUnspentOutputProvider!
    private var mockTransactionSizeCalculator: MockTransactionSizeCalculator!
    private var mockAddressConverter: MockAddressConverter!
    private var mockInputSigner: MockInputSigner!
    private var mockScriptBuilder:  MockScriptBuilder!
    private var mockFactory: MockFactory!

    private var transactionBuilder: TransactionBuilder!

    private var unspentOutputs: SelectedUnspentOutputInfo!
    private var transaction: Transaction!
    private var toOutput: TransactionOutput!
    private var changeOutput: TransactionOutput!
    private var input: TransactionInput!
    private var totalInputValue: Int!
    private var value: Int!
    private var feeRate: Int!
    private var fee: Int!
    private var changePubKey: PublicKey!
    private var toAddress: String!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        realm = mockWalletKit.mockRealm

        mockUnspentOutputSelector = mockWalletKit.mockUnspentOutputSelector
        mockUnspentOutputProvider = mockWalletKit.mockUnspentOutputProvider
        mockTransactionSizeCalculator = mockWalletKit.mockTransactionSizeCalculator
        mockAddressConverter = mockWalletKit.mockAddressConverter
        mockInputSigner = mockWalletKit.mockInputSigner
        mockScriptBuilder = mockWalletKit.mockScriptBuilder
        mockFactory = mockWalletKit.mockFactory

        transactionBuilder = TransactionBuilder(unspentOutputSelector: mockUnspentOutputSelector, unspentOutputProvider: mockUnspentOutputProvider, transactionSizeCalculator: mockTransactionSizeCalculator, addressConverter: mockAddressConverter, inputSigner: mockInputSigner, scriptBuilder: mockScriptBuilder, factory: mockFactory)

        changePubKey = TestData.pubKey()
        toAddress = "2QVLmkcuXLpmuRz9C8BiccAMujm4"

        let previousTransaction = TestData.p2pkhTransaction
        try! realm.write {
            realm.add(previousTransaction, update: true)
        }

        unspentOutputs = SelectedUnspentOutputInfo(outputs: [previousTransaction.outputs[0]], totalValue: previousTransaction.outputs[0].value, fee: 1008)
        totalInputValue = unspentOutputs.outputs[0].value
        value = 10782000
        feeRate = 6
        fee = 1008

        transaction = Transaction(version: 1, inputs: [], outputs: [])
        input = TransactionInput(withPreviousOutputTxReversedHex: previousTransaction.reversedHashHex, previousOutputIndex: unspentOutputs.outputs[0].index, script: Data(), sequence: 0)
        toOutput = TransactionOutput(withValue: value - fee, index: 0, lockingScript: Data(), type: .p2pkh, address: toAddress, keyHash: nil)
        changeOutput = TransactionOutput(withValue: totalInputValue - value, index: 1, lockingScript: Data(), type: .p2pkh, keyHash: changePubKey.keyHash)

        stub(mockUnspentOutputSelector) { mock in
            when(mock.select(value: any(), feeRate: any(), senderPay: any(), outputs: any())).thenReturn(unspentOutputs)
        }

        stub(mockUnspentOutputProvider) { mock in
            when(mock.allUnspentOutputs()).thenReturn(unspentOutputs.outputs)
        }

        stub(mockTransactionSizeCalculator) { mock in
            when(mock.outputSize(type: any())).thenReturn(34)
        }

        stub(mockInputSigner) { mock in
            when(mock.sigScriptData(transaction: any(), index: any())).thenReturn([Data()])
        }

        stub(mockAddressConverter) { mock in
            when(mock.convert(address: any())).thenReturn(Data())
        }

        stub(mockScriptBuilder) { mock in
            when(mock.lockingScript(type: any(), params: any())).thenReturn(Data())
            when(mock.unlockingScript(params: any())).thenReturn(Data())
        }

        stub(mockFactory) { mock in
            when(mock.transaction(version: any(), inputs: any(), outputs: any(), lockTime: any())).thenReturn(transaction)
        }

        stub(mockFactory) { mock in
            when(mock.transactionInput(withPreviousOutputTxReversedHex: any(), previousOutputIndex: any(), script: any(), sequence: any())).thenReturn(input)
        }

        stub(mockFactory) { mock in
            when(mock.transactionOutput(withValue: any(), index: any(), lockingScript: any(), type: equal(to: ScriptType.p2pkh), address: equal(to: toAddress), keyHash: any(), publicKey: any())).thenReturn(toOutput)
            when(mock.transactionOutput(withValue: any(), index: any(), lockingScript: any(), type: equal(to: ScriptType.p2pkh), address: equal(to: changePubKey.address), keyHash: any(), publicKey: any())).thenReturn(changeOutput)
        }
    }

    override func tearDown() {
        realm = nil
        unspentOutputs = nil
        mockUnspentOutputSelector = nil
        mockUnspentOutputProvider = nil
        mockAddressConverter = nil
        mockInputSigner = nil
        mockFactory = nil
        transactionBuilder = nil
        changePubKey = nil
        toAddress = nil
        value = nil
        feeRate = nil
        fee = nil

        super.tearDown()
    }

    func testBuildTransaction() {
        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: false, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertNotEqual(resultTx.reversedHashHex, "")
        XCTAssertEqual(resultTx.status, .new)
        XCTAssertEqual(resultTx.isMine, true)
        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs.outputs[0])
        XCTAssertEqual(resultTx.outputs.count, 2)
        XCTAssertEqual(resultTx.outputs[0].address, toAddress)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)  // value - fee
        XCTAssertEqual(resultTx.outputs[1].keyHash, changePubKey.keyHash)
        XCTAssertEqual(resultTx.outputs[1].value, unspentOutputs.outputs[0].value - value)
    }

    func testBuildTransactionSenderPay() {
        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: true, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.outputs[0].value, value)  // value - fee
        verify(mockFactory).transactionOutput(withValue: unspentOutputs.outputs[0].value - value - fee, index: 1, lockingScript: any(), type: equal(to: ScriptType.p2pkh), address: equal(to: changePubKey.address), keyHash: any(), publicKey: any())
    }

    func testWithoutChangeOutput() {
        value = totalInputValue

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: false, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs.outputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].address, toAddress)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }

    func testChangeNotAddedForDust() {
        value = totalInputValue - mockTransactionSizeCalculator.outputSize(type: .p2pkh) * feeRate

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: false, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs.count, 1)
        XCTAssertEqual(resultTx.inputs[0].previousOutput!, unspentOutputs.outputs[0])
        XCTAssertEqual(resultTx.outputs.count, 1)
        XCTAssertEqual(resultTx.outputs[0].address, toAddress)
        XCTAssertEqual(resultTx.outputs[0].value, value - fee)
    }

    func testInputsSigned() {
        let sigData = [Data(hex: "000001")!, Data(hex: "000002")!]
        let sigScript = Data(hex: "000001000002")!

        stub(mockInputSigner) { mock in
            when(mock.sigScriptData(transaction: any(), index: any())).thenReturn(sigData)
        }

        stub(mockScriptBuilder) { mock in
            when(mock.unlockingScript(params: any())).thenReturn(sigScript)
        }

        var resultTx = Transaction()
        do {
            resultTx = try transactionBuilder.buildTransaction(value: value, feeRate: feeRate, senderPay: false, changePubKey: changePubKey, toAddress: toAddress)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        XCTAssertEqual(resultTx.inputs[0].signatureScript, sigScript)
    }

    func testTransactionFee() {
        let outputTx = TestData.p2pkhTransaction
        outputTx.outputs[0].value = 11805400
        outputTx.outputs[0].scriptType = .p2pkh

        stub(mockUnspentOutputSelector) { mock in
            when(mock.select(value: any(), feeRate: any(), senderPay: any(), outputs: any())).thenReturn(SelectedUnspentOutputInfo(outputs: [outputTx.outputs[0]], totalValue: 11805400, fee: 112800))
        }

        do {
            let result = try transactionBuilder.fee(for: value, feeRate: 600, senderPay: true, type: .p2pkh)
            XCTAssertEqual(result, 133200)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

}
