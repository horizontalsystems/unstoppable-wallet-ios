//import XCTest
//import RxSwift
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class BalanceSorterTests: XCTestCase {
//    private var sorter: BalanceSorter!
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
//        let ethereum = Coin.mock(title: "Ethereum", code: "ETH", type: .ethereum)
//        ethereumItem = BalanceItem(coin: ethereum)
//        ethereumItem.rate = Rate(coinCode: ethereum.code, currencyCode: "USD", value: 10, date: Date(), isLatest: true)
//        ethereumItem.balance = Decimal(string: "0.0012")!
//
//        cashItem = BalanceItem(coin: Coin.mock(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash))
//        cashItem.rate = nil
//        cashItem.balance = Decimal(string: "112")!
//
//
//        sorter = BalanceSorter()
//    }
//
//    override func tearDown() {
//        sorter = nil
//
//        super.tearDown()
//    }
//
//    func testSort_Value() {
//        XCTAssertEqual([bitcoinItem, ethereumItem, cashItem], sorter.sort(items: [cashItem, ethereumItem, bitcoinItem], sort: .value))
//    }
//
//    func testSort_ABC() {
//        XCTAssertEqual([bitcoinItem, cashItem, ethereumItem], sorter.sort(items: [cashItem, ethereumItem, bitcoinItem], sort: .name))
//    }
//
//}
