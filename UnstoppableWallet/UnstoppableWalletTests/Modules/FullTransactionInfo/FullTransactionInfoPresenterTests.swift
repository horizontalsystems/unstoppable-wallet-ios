//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class FullTransactionInfoPresenterTests: XCTestCase {
//    private var mockView: MockIFullTransactionInfoView!
//    private var mockInteractor: MockIFullTransactionInfoInteractor!
//    private var mockRouter: MockIFullTransactionInfoRouter!
//    private var mockState: MockIFullTransactionInfoState!
//
//    private var presenter: FullTransactionInfoPresenter!
//    private var transactionHash: String!
//    private var providerName: String!
//    private var fullUrl: String!
//    private var transactionRecord: FullTransactionRecord!
//
//    private let coin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//
//    override func setUp() {
//        super.setUp()
//
//        providerName = "test_provider"
//        transactionRecord = FullTransactionRecord(providerName: providerName, sections: [
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
//        mockView = MockIFullTransactionInfoView()
//        stub(mockView) { mock in
//            when(mock.showLoading()).thenDoNothing()
//            when(mock.hideLoading()).thenDoNothing()
//            when(mock.showError(providerName: any())).thenDoNothing()
//            when(mock.hideError()).thenDoNothing()
//            when(mock.reload()).thenDoNothing()
//            when(mock.showCopied()).thenDoNothing()
//        }
//        mockRouter = MockIFullTransactionInfoRouter()
//        stub(mockRouter) { mock in
//            when(mock.open(url: any())).thenDoNothing()
//            when(mock.openProviderSettings(coin: any(), transactionHash: any())).thenDoNothing()
//            when(mock.share(value: any())).thenDoNothing()
//            when(mock.close()).thenDoNothing()
//        }
//        fullUrl = "test_url_with_hash"
//        mockInteractor = MockIFullTransactionInfoInteractor()
//        stub(mockInteractor) { mock in
//            when(mock.reachableConnection.get).thenReturn(true)
//            when(mock.didLoad()).thenDoNothing()
//            when(mock.url(for: any())).thenReturn(fullUrl)
//            when(mock.updateProvider(for: any())).thenDoNothing()
//            when(mock.retrieveTransactionInfo(transactionHash: any())).thenDoNothing()
//            when(mock.copyToPasteboard(value: any())).thenDoNothing()
//        }
//        transactionHash = "test_hash"
//        mockState = MockIFullTransactionInfoState()
//        stub(mockState) { mock in
//            when(mock.transactionHash.get).thenReturn(transactionHash)
//            when(mock.coin.get).thenReturn(coin)
//            when(mock.transactionRecord.get).thenReturn(transactionRecord)
//            when(mock.set(transactionRecord: any())).thenDoNothing()
//        }
//        presenter = FullTransactionInfoPresenter(interactor: mockInteractor, router: mockRouter, state: mockState)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        transactionRecord = nil
//        fullUrl = nil
//        providerName = nil
//
//        mockRouter = nil
//        mockInteractor = nil
//        mockView = nil
//        mockState = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testDidLoad() {
//        presenter.viewDidLoad()
//
//        verify(mockInteractor).updateProvider(for: equal(to: coin))
//        verify(mockInteractor).didLoad()
//        verify(mockView).showLoading()
//        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)
//    }
//
//    func testOnProviderChanged() {
//        presenter.onProviderChanged()
//
//        verify(mockState).set(transactionRecord: equal(to: nil))
//        verify(mockView).reload()
//
//        verify(mockInteractor).updateProvider(for: equal(to: coin))
//        verify(mockView).showLoading()
//        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)
//    }
//
//    func testDidReceiveTransactionRecord() {
//        presenter.didReceive(transactionRecord: transactionRecord)
//        verify(mockState).set(transactionRecord: equal(to: transactionRecord))
//        verify(mockView).hideLoading()
//        verify(mockView).reload()
//    }
//
//    func testTapNothing() {
//        let value = "test_nothing"
//        let item = FullTransactionItem(title: "test_item", value: value, clickable: false)
//        presenter.onTap(item: item)
//
//        verifyNoMoreInteractions(mockInteractor)
//        verifyNoMoreInteractions(mockRouter)
//    }
//
//    func testTapCopy() {
//        let value = "test_copy"
//        let item = FullTransactionItem(title: "test_item", value: value, clickable: true)
//        presenter.onTap(item: item)
//
//        verify(mockInteractor).copyToPasteboard(value: equal(to: value))
//        verify(mockView).showCopied()
//
//        verifyNoMoreInteractions(mockInteractor)
//        verifyNoMoreInteractions(mockView)
//    }
//
//    func testTapHash() {
//        presenter.onTapHash()
//
//        verify(mockInteractor).copyToPasteboard(value: mockState.transactionHash)
//        verify(mockView).showCopied()
//    }
//
//    func testTapOpenUrl() {
//        let value = "test_url"
//        let item = FullTransactionItem(title: "test_item", value: nil, clickable: true, url: value)
//        presenter.onTap(item: item)
//
//        verify(mockRouter).open(url: equal(to: value))
//
//        verifyNoMoreInteractions(mockRouter)
//    }
//
//    func testOnTapChangeResource() {
//        presenter.onTapChangeResource()
//        verify(mockRouter).openProviderSettings(coin: equal(to: coin), transactionHash: transactionHash)
//    }
//
//    func testOnTapProviderLink() {
//        presenter.onTapProviderLink()
//        verify(mockRouter).open(url: equal(to: fullUrl))
//    }
//
//    func testClose() {
//        presenter.onClose()
//
//        verify(mockView).hideLoading()
//        verify(mockRouter).close()
//    }
//
//    func testShowError() {
//        presenter.onError(providerName: providerName)
//
//        verify(mockView).hideLoading()
//        verify(mockView).showError(providerName: equal(to: providerName))
//    }
//
//    func testOnConnectionRestored() {
//        stub(mockState) { mock in
//            when(mock.transactionHash.get).thenReturn(transactionHash)
//            when(mock.transactionRecord.get).thenReturn(nil)
//            when(mock.set(transactionRecord: any())).thenDoNothing()
//        }
//
//        presenter.onConnectionChanged()
//
//        verify(mockView).hideError()
//        verify(mockView).showLoading()
//        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)
//    }
//
//    func testOnConnectionRestoredExistData() {
//        presenter.onConnectionChanged()
//
//        verify(mockInteractor, never()).retrieveTransactionInfo(transactionHash: transactionHash)
//    }
//
//    func testOnRetryLoad() {
//        stub(mockState) { mock in
//            when(mock.transactionRecord.get).thenReturn(nil)
//        }
//        presenter.onRetryLoad()
//
//        verify(mockView).hideError()
//        verify(mockView).showLoading()
//        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)
//    }
//
//    func testOnShare() {
//        presenter.onShare()
//
//        verify(mockRouter).share(value: fullUrl)
//    }
//
//    func testTransactionHash() {
//        XCTAssertEqual(transactionHash, presenter.transactionHash)
//    }
//
//}
