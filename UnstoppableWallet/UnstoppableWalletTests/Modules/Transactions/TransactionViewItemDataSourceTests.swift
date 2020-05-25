//import XCTest
//import Cuckoo
//import DeepDiff
//@testable import Unstoppable_Dev_T
//
//class TransactionViewItemDataSourceTests: XCTestCase {
//    private var mockViewItemDelegate: MockITransactionViewItemLoaderDelegate!
//    private var mockDiffer: MockIDiffer!
//    private var state: TransactionViewItemLoaderState!
//
//    private var dataSource: TransactionViewItemLoader!
//
//    private let bitcoin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    let date = Date()
//
//    override func setUp() {
//        super.setUp()
//
//        mockViewItemDelegate = MockITransactionViewItemLoaderDelegate()
//        mockDiffer = MockIDiffer()
//
//        state = TransactionViewItemLoaderState()
//        state.items = originalItems
//        state.viewItems = originalViewItems
//
//        dataSource = TransactionViewItemLoader(state: state, differ: mockDiffer, async: false)
//        dataSource.delegate = mockViewItemDelegate
//    }
//
//    override func tearDown() {
//        mockViewItemDelegate = nil
//        mockDiffer = nil
//
//        state = nil
//        dataSource = nil
//
//        super.tearDown()
//    }
//
//    func testItemsInsert_reload() {
////        var newItems = originalItems
////        let newItem = TransactionItem(
////                coin: bitcoin,
////                record: TransactionRecord(
////                        transactionHash: "d",
////                        transactionIndex: 0,
////                        interTransactionIndex: 0,
////                        blockHeight: 4,
////                        amount: 2,
////                        date: date,
////                        from: [TransactionAddress(address: "asd", mine: true)],
////                        to: [TransactionAddress(address: "asdf", mine: false)])
////        )
////        newItems.insert(newItem, at: 1)
////
////        stub(mockDiffer) { mock in
////            when(mock.changes(old: equal(to: originalItems), new: equal(to: newItems))).thenReturn([Change.insert(Insert(item: newItem, index: 1))])
////        }
////
////        dataSource.reload(with: newItems, animated: false)
////
////        XCTAssertEqual(newItems, state.items)
//    }
//
//}
//
//extension TransactionViewItemDataSourceTests {
//
//    var originalItems: [TransactionItem] {
//        return [
//            TransactionItem(
//                    wallet: bitcoin,
//                    record: TransactionRecord(
//                            transactionHash: "a",
//                            transactionIndex: 0,
//                            interTransactionIndex: 0,
//                            blockHeight: 1,
//                            amount: 2,
//                            date: date,
//                            from: [TransactionAddress(address: "asd", mine: true)],
//                            to: [TransactionAddress(address: "asdf", mine: false)])
//            ),
//            TransactionItem(
//                    wallet: bitcoin,
//                    record: TransactionRecord(
//                            transactionHash: "b",
//                            transactionIndex: 0,
//                            interTransactionIndex: 0,
//                            blockHeight: 2,
//                            amount: 3,
//                            date: date,
//                            from: [TransactionAddress(address: "asd", mine: true)],
//                            to: [TransactionAddress(address: "asdf", mine: false)])
//            ),
//            TransactionItem(
//                    wallet: bitcoin,
//                    record: TransactionRecord(
//                            transactionHash: "c",
//                            transactionIndex: 0,
//                            interTransactionIndex: 0,
//                            blockHeight: 3,
//                            amount: 4,
//                            date: date,
//                            from: [TransactionAddress(address: "asd", mine: true)],
//                            to: [TransactionAddress(address: "asdf", mine: false)])
//            )
//        ]
//    }
//
//    var originalViewItems: [TransactionViewItem] {
//        return [
//            TransactionViewItem(
//                    wallet: bitcoin,
//                    transactionHash: "a",
//                    coinValue: CoinValue(coin: bitcoin, value: 2),
//                    currencyValue: nil,
//                    from: "asd",
//                    to: "asdf",
//                    incoming: false,
//                    date: date,
//                    status: .completed,
//                    rate: nil),
//            TransactionViewItem(
//                    wallet: bitcoin,
//                    transactionHash: "b",
//                    coinValue: CoinValue(coin: bitcoin, value: 2),
//                    currencyValue: nil,
//                    from: "asd",
//                    to: "asdf",
//                    incoming: false,
//                    date: date,
//                    status: .completed,
//                    rate: nil),
//            TransactionViewItem(
//                    wallet: bitcoin,
//                    transactionHash: "c",
//                    coinValue: CoinValue(coin: bitcoin, value: 2),
//                    currencyValue: nil,
//                    from: "asd",
//                    to: "asdf",
//                    incoming: false,
//                    date: date,
//                    status: .completed,
//                    rate: nil)
//        ]
//    }
//}