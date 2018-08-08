import XCTest
import Cuckoo
@testable import WalletKit

class UnspentOutputSelectorTests: XCTestCase {

    private var unspentOutputSelector: UnspentOutputSelector!
    private var outputs: [TransactionOutput]!

    override func setUp() {
        super.setUp()

        unspentOutputSelector = UnspentOutputSelector()
        outputs = [TransactionOutputFactory.shared.transactionOutput(withValue: 1, withLockingScript: Data(), withIndex: 0),
                   TransactionOutputFactory.shared.transactionOutput(withValue: 2, withLockingScript: Data(), withIndex: 0),
                   TransactionOutputFactory.shared.transactionOutput(withValue: 4, withLockingScript: Data(), withIndex: 0),
                   TransactionOutputFactory.shared.transactionOutput(withValue: 8, withLockingScript: Data(), withIndex: 0),
                   TransactionOutputFactory.shared.transactionOutput(withValue: 16, withLockingScript: Data(), withIndex: 0)
        ]
    }

    override func tearDown() {
        unspentOutputSelector = nil
        outputs = nil

        super.tearDown()
    }

    func testExactlyValue() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 4, outputs: outputs)
            XCTAssertEqual(selectedOutputs, [outputs[2]])
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testSummaryValue() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 11, outputs: outputs)
            XCTAssertEqual(selectedOutputs, [outputs[0], outputs[1], outputs[2], outputs[3]])
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testNotEnoughError() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 35, outputs: outputs)
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.notEnough)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

    func testEmptyOutputsError() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 35, outputs: [])
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputSelector.SelectorError {
            XCTAssertEqual(error, UnspentOutputSelector.SelectorError.emptyOutputs)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

}
