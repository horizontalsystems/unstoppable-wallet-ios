import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class UnspentOutputSelectorTests: XCTestCase {

    private var unspentOutputSelector: UnspentOutputSelector!
    private var outputs: [TransactionOutput]!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        unspentOutputSelector = UnspentOutputSelector(calculator: mockWalletKit.mockTransactionSizeCalculator)
        stub(mockWalletKit.mockTransactionSizeCalculator) { mock in
            when(mock.inputSize(type: any())).thenReturn(149)
            when(mock.outputSize(type: any())).thenReturn(34)
            when(mock.transactionSize()).thenReturn(10)
        }
        outputs = [TransactionOutput(withValue: 100000, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data()),
                   TransactionOutput(withValue: 200000, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data()),
                   TransactionOutput(withValue: 400000, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data()),
                   TransactionOutput(withValue: 800000, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data()),
                   TransactionOutput(withValue: 1600000, index: 0, lockingScript: Data(), type: .p2pkh, keyHash: Data())
        ]
    }

    override func tearDown() {
        unspentOutputSelector = nil
        outputs = nil

        super.tearDown()
    }

    func testExactlyValueReceiverPay() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 400000, feeRate: 600, senderPay: false, outputs: outputs)
            XCTAssertEqual(selectedOutputs.outputs, [outputs[2]])
            XCTAssertEqual(selectedOutputs.totalValue, 400000)
            XCTAssertEqual(selectedOutputs.fee, 115800)
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testExactlyValueSenderPay() {
        do {
            let fee = (10 + 149 + 29) * 600 // transaction + 1 input + 1 output
            let selectedOutputs = try unspentOutputSelector.select(value: 339950 - fee, feeRate: 600, senderPay: true, outputs: outputs)
            XCTAssertEqual(selectedOutputs.outputs, [outputs[2]])
            XCTAssertEqual(selectedOutputs.totalValue, 400000)
            XCTAssertEqual(selectedOutputs.fee, 115800)
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testSummaryValueReceiverPay() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 700000, feeRate: 600, senderPay: false, outputs: outputs)
            XCTAssertEqual(selectedOutputs.outputs, [outputs[0], outputs[1], outputs[2]])
            XCTAssertEqual(selectedOutputs.totalValue, 700000)
            XCTAssertEqual(selectedOutputs.fee, 294600)
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testSummaryValueSenderPay() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 700000, feeRate: 600, senderPay: true, outputs: outputs)
            XCTAssertEqual(selectedOutputs.outputs, [outputs[0], outputs[1], outputs[2], outputs[3]])
            XCTAssertEqual(selectedOutputs.totalValue, 1500000)
            XCTAssertEqual(selectedOutputs.fee, 384000)
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testNotEnoughErrorReceiverPay() {
        do {
            _ = try unspentOutputSelector.select(value: 3100100, feeRate: 600, senderPay: false, outputs: outputs)
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.notEnough)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

    func testNotEnoughErrorSenderPay() {
        do {
            _ = try unspentOutputSelector.select(value: 3090000, feeRate: 600, senderPay: true, outputs: outputs)
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.notEnough)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

    func testEmptyOutputsError() {
        do {
            _ = try unspentOutputSelector.select(value: 3500000, feeRate: 600, senderPay: false, outputs: [])
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.emptyOutputs)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

}
