import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionExtractorTests: XCTestCase {

    private var extractor: TransactionExtractor!

    private var p2pkhTransaction: Transaction!
    private var p2pkTransaction: Transaction!

    override func setUp() {
        super.setUp()

        extractor = TransactionExtractor()

        p2pkhTransaction = TestHelper.p2pkhTransaction
        p2pkTransaction = TestHelper.p2pkTransaction
    }

    override func tearDown() {
        extractor = nil

        p2pkhTransaction = nil
        p2pkTransaction = nil

        super.tearDown()
    }

    func testExtractP2pkhTransaction() {
        let keyHash = Data(hex: "1ec865abcb88cec71c484d4dadec3d7dc0271a7b")!
        do {
            try extractor.extract(message: p2pkhTransaction)

            if let testHash = p2pkhTransaction.outputs[0].keyHash {
                XCTAssertEqual(testHash, keyHash)
                XCTAssertEqual(p2pkhTransaction.outputs[0].scriptType, .p2pkh)
            } else {
                XCTFail("KeyHash not found!")
            }
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testExtractP2pkTransaction() {
        let keyHash = Data(hex: "e4de5d630c5cacd7af96418a8f35c411c8ff3c06")!
        do {
            try extractor.extract(message: p2pkTransaction)

            if let testHash = p2pkTransaction.outputs[0].keyHash {
                XCTAssertEqual(testHash, keyHash)
                XCTAssertEqual(p2pkTransaction.outputs[0].scriptType, .p2pk)
            } else {
                XCTFail("KeyHash not found!")
            }
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

}
