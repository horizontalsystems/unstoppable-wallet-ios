//import XCTest
//import RxSwift
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class BalanceDataSourceTests: XCTestCase {
//    private var mockSorter: MockIBalanceSorter!
//
//    private var dataSource: BalanceItemDataSource!
//
//    private var bitcoinItem: BalanceItem!
//    private var ethereumItem: BalanceItem!
//    private var cashItem: BalanceItem!
//
//    override func setUp() {
//        super.setUp()
//
//        let bitcoin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//        bitcoinItem = BalanceItem(coin: bitcoin)
//        bitcoinItem.rate = Rate(coinCode: bitcoin.code, currencyCode: "USD", value: 10, date: Date(), isLatest: true)
//        bitcoinItem.balance = Decimal(string: "10")!
//
//        ethereumItem = BalanceItem(coin: Coin.mock(title: "Ethereum", code: "ETH", type: .ethereum))
//        ethereumItem.rate = Rate(coinCode: bitcoin.code, currencyCode: "USD", value: 10, date: Date(), isLatest: true)
//        ethereumItem.balance = Decimal(string: "0.0012")!
//
//        cashItem = BalanceItem(coin: Coin.mock(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash))
//        cashItem.rate = nil
//        cashItem.balance = Decimal(string: "112")!
//
//        mockSorter = MockIBalanceSorter()
//
//        dataSource = BalanceItemDataSource(sorter: mockSorter)
//    }
//
//    override func tearDown() {
//        mockSorter = nil
//
//        dataSource = nil
//
//        super.tearDown()
//    }
//
//}
