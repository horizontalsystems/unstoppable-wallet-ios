import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class TransactionsPresenterTests: XCTestCase {
    private var mockRouter: MockITransactionsRouter!
    private var mockInteractor: MockITransactionsInteractor!
    private var mockView: MockITransactionsView!
    private var mockFactory: MockITransactionViewItemFactory!

    private var presenter: TransactionsPresenter!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private var bitcoinRecord = TransactionRecord()
    private var etherRecord = TransactionRecord()

    private var bitcoinViewItem = TransactionViewItem(transactionHash: "hash", coinValue: CoinValue(coin: "", value: 0), currencyValue: nil, from: nil, to: nil, incoming: true, date: nil, status: .pending)
    private var etherViewItem = TransactionViewItem(transactionHash: "", coinValue: CoinValue(coin: "", value: 0), currencyValue: nil, from: nil, to: nil, incoming: true, date: nil, status: .pending)

    override func setUp() {
        super.setUp()

        mockRouter = MockITransactionsRouter()
        mockInteractor = MockITransactionsInteractor()
        mockView = MockITransactionsView()
        mockFactory = MockITransactionViewItemFactory()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.reload()).thenDoNothing()
            when(mock.show(filters: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.openTransactionInfo(transactionHash: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.retrieveFilters()).thenDoNothing()
            when(mock.refresh()).thenDoNothing()
            when(mock.set(coin: equal(to: bitcoin))).thenDoNothing()
            when(mock.set(coin: equal(to: ether))).thenDoNothing()
            when(mock.recordsCount.get).thenReturn(3)
            when(mock.record(forIndex: 0)).thenReturn(bitcoinRecord)
            when(mock.record(forIndex: 1)).thenReturn(etherRecord)
        }
        stub(mockFactory) { mock in
            when(mock.item(fromRecord: equal(to: bitcoinRecord))).thenReturn(bitcoinViewItem)
            when(mock.item(fromRecord: equal(to: etherRecord))).thenReturn(etherViewItem)
        }

        presenter = TransactionsPresenter(interactor: mockInteractor, router: mockRouter, factory: mockFactory)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil
        mockFactory = nil

        presenter = nil

        super.tearDown()
    }

    func testShowTitle() {
        presenter.viewDidLoad()
        verify(mockView).set(title: "transactions.title")
    }

    func testInitialFiltersRequest() {
        presenter.viewDidLoad()
        verify(mockInteractor).retrieveFilters()
    }

    func testInitialItems() {
        XCTAssertTrue(presenter.item(forIndex: 0) === bitcoinViewItem)
        XCTAssertTrue(presenter.item(forIndex: 1) === etherViewItem)
    }

    func testRefresh() {
        presenter.refresh()
        verify(mockInteractor).refresh()
    }

    func testUpdateFilterCoin() {
        presenter.onFilterSelect(coin: bitcoin)
        verify(mockInteractor).set(coin: equal(to: bitcoin))
    }

    func testItemsCount_OnFilterSelect() {
        stub(mockInteractor) { mock in
            when(mock.recordsCount.get).thenReturn(1)
        }

        presenter.onFilterSelect(coin: bitcoin)
        XCTAssertEqual(presenter.itemsCount, 1)
    }

    func testItemIsRight_OnFilterSelect() {
        stub(mockInteractor) { mock in
            when(mock.record(forIndex: 0)).thenReturn(etherRecord)
        }

        presenter.onFilterSelect(coin: ether)

        XCTAssertTrue(presenter.item(forIndex: 0) === etherViewItem)
    }

    func testOpenTransactionInfo() {
        presenter.onTransactionItemClick(transaction: bitcoinViewItem)
        verify(mockRouter).openTransactionInfo(transactionHash: equal(to: bitcoinViewItem.transactionHash))
    }

    func testDidRetrieveFilters() {
        let expectedAllFilter = TransactionFilterItem(coin: nil, name: "transactions.filter_all")
        let expectedBitcoinFilter = TransactionFilterItem(coin: bitcoin, name: "coin.\(bitcoin)")
        let expectedEtherFilter = TransactionFilterItem(coin: ether, name: "coin.\(ether)")
        let expectedFilters = [expectedAllFilter, expectedBitcoinFilter, expectedEtherFilter]

        presenter.didRetrieve(filters: [bitcoin, ether])
        verify(mockView).show(filters: equal(to: expectedFilters))
    }

    func testDidUpdateDataSource() {
        presenter.didUpdateDataSource()
        verify(mockView).reload()
    }

}
