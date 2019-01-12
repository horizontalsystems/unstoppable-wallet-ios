import XCTest
import Cuckoo
@testable import Bank_Dev_T

class FullTransactionInfoStateTests: XCTestCase {

    private var state: FullTransactionInfoState!

    private var transactionHash: String!
    private var transactionRecord: FullTransactionRecord!

    override func setUp() {
        super.setUp()

        transactionHash = "test_hash"
        transactionRecord = FullTransactionRecord(sections: [
            FullTransactionSection(title: nil, items: [
                FullTransactionItem(title: "item1", value: "value1", clickable: false, url: nil, showExtra: .none),
                FullTransactionItem(title: "item2", value: "value2", clickable: true, url: nil, showExtra: .none)
            ]
            ),
            FullTransactionSection(title: "section2", items: [
                FullTransactionItem(title: "item1", value: "value1", clickable: false, url: nil, showExtra: .none),
                FullTransactionItem(title: "item2", value: "value2", clickable: true, url: nil, showExtra: .none)
            ]
            )
        ])

        state = FullTransactionInfoState(providerName: "test_name", url: "test_url", transactionHash: transactionHash)
    }

    override func tearDown() {
        state = nil

        super.tearDown()
    }

    func testTransactionHash() {
        XCTAssertEqual(state.transactionHash, transactionHash)
    }

    func testSetRecord() {
        XCTAssertEqual(state.transactionRecord, nil)

        state.set(transactionRecord: transactionRecord)
        XCTAssertEqual(state.transactionRecord, transactionRecord)
    }

}
