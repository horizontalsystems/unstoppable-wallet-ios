//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class FullTransactionInfoStateTests: XCTestCase {
//
//    private var state: FullTransactionInfoState!
//
//    private var transactionHash: String!
//    private var transactionRecord: FullTransactionRecord!
//
//    override func setUp() {
//        super.setUp()
//
//        transactionHash = "test_hash"
//        transactionRecord = FullTransactionRecord(providerName: "test_provider", sections: [
//            FullTransactionSection(title: nil, items: [
//                FullTransactionItem(title: "item1", value: "value1", clickable: false, url: nil, showExtra: .none),
//                FullTransactionItem(title: "item2", value: "value2", clickable: true, url: nil, showExtra: .none)
//            ]
//            ),
//            FullTransactionSection(title: "section2", items: [
//                FullTransactionItem(title: "item1", value: "value1", clickable: false, url: nil, showExtra: .none),
//                FullTransactionItem(title: "item2", value: "value2", clickable: true, url: nil, showExtra: .none)
//            ]
//            )
//        ])
//
//        state = FullTransactionInfoState(coin: Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin), transactionHash: transactionHash)
//    }
//
//    override func tearDown() {
//        state = nil
//
//        super.tearDown()
//    }
//
//    func testTransactionHash() {
//        XCTAssertEqual(state.transactionHash, transactionHash)
//    }
//
//    func testSetRecord() {
//        XCTAssertEqual(state.transactionRecord, nil)
//
//        state.set(transactionRecord: transactionRecord)
//        XCTAssertEqual(state.transactionRecord, transactionRecord)
//    }
//
//}
