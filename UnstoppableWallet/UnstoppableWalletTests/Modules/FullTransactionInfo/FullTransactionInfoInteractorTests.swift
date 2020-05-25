//import XCTest
//import Cuckoo
//import RxSwift
//@testable import Unstoppable_Dev_T
//
//class FullTransactionInfoInteractorTests: XCTestCase {
//    private var mockProviderFactory: MockIFullTransactionInfoProviderFactory!
//    private var mockProvider: MockIFullTransactionInfoProvider!
//    private var mockDelegate: MockIFullTransactionInfoInteractorDelegate!
//    private var mockPasteboardManager: MockIPasteboardManager!
//    private var mockReachabilityManager: MockIReachabilityManager!
//    private var mockDataProviderManager: MockIFullTransactionDataProviderManager!
//
//    private var interactor: FullTransactionInfoInteractor!
//    private var transactionHash: String!
//    private var providerName: String!
//    private var reachabilitySignal: Signal!
//    private var dataProviderSignal: Signal!
//    private var transactionRecord: FullTransactionRecord!
//
//    private let coin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//
//    override func setUp() {
//        super.setUp()
//
//        providerName = "test_provider"
//        transactionHash = "test_hash"
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
//        mockProvider = MockIFullTransactionInfoProvider()
//        stub(mockProvider) { mock in
//            when(mock.retrieveTransactionInfo(transactionHash: any())).thenReturn(Single.just(transactionRecord))
//            when(mock.url(for: any())).thenReturn("test_url")
//            when(mock.providerName.get).thenReturn(providerName)
//        }
//        mockProviderFactory = MockIFullTransactionInfoProviderFactory()
//        stub(mockProviderFactory) { mock in
//            when(mock.provider(for: any())).thenReturn(mockProvider)
//        }
//        mockDelegate = MockIFullTransactionInfoInteractorDelegate()
//        stub(mockDelegate) { mock in
//            when(mock.onProviderChanged()).thenDoNothing()
//            when(mock.didReceive(transactionRecord: any())).thenDoNothing()
//            when(mock.onError(providerName: any())).thenDoNothing()
//            when(mock.onConnectionChanged()).thenDoNothing()
//        }
//        mockPasteboardManager = MockIPasteboardManager()
//        stub(mockPasteboardManager) { mock in
//            when(mock.set(value: any())).thenDoNothing()
//        }
//        reachabilitySignal = Signal()
//        mockReachabilityManager = MockIReachabilityManager()
//        stub(mockReachabilityManager) { mock in
//            when(mock.isReachable.get).thenReturn(true)
//            when(mock.reachabilitySignal.get).thenReturn(reachabilitySignal)
//        }
//        dataProviderSignal = Signal()
//        mockDataProviderManager = MockIFullTransactionDataProviderManager()
//        stub(mockDataProviderManager) { mock in
//            when(mock.dataProviderUpdatedSignal.get).thenReturn(dataProviderSignal)
//        }
//
//        interactor = FullTransactionInfoInteractor(providerFactory: mockProviderFactory, reachabilityManager: mockReachabilityManager, dataProviderManager: mockDataProviderManager, pasteboardManager: mockPasteboardManager, async: false)
//        interactor.delegate = mockDelegate
//    }
//
//    override func tearDown() {
//        transactionHash = nil
//        providerName = nil
//        transactionRecord = nil
//        reachabilitySignal = nil
//
//        mockProvider = nil
//        mockPasteboardManager = nil
//        mockReachabilityManager = nil
//        mockDataProviderManager = nil
//
//        interactor = nil
//
//        super.tearDown()
//    }
//
//    func testUpdateProvider() {
//        interactor.updateProvider(for: coin)
//        verify(mockProviderFactory).provider(for: equal(to: coin))
//    }
//
//    func testReachableConnection() {
//        XCTAssertEqual(interactor.reachableConnection, true)
//
//        stub(mockReachabilityManager) { mock in
//            when(mock.isReachable.get).thenReturn(false)
//        }
//
//        XCTAssertEqual(interactor.reachableConnection, false)
//    }
//
//    func testDidLoad() {
//        interactor.didLoad()
//        reachabilitySignal.notify()
//        dataProviderSignal.notify()
//
//        waitForMainQueue()
//        verify(mockDelegate).onConnectionChanged()
//        verify(mockDelegate).onProviderChanged()
//    }
//
//    func testRetrieve() {
//        interactor.updateProvider(for: coin)
//
//        interactor.retrieveTransactionInfo(transactionHash: transactionHash)
//        waitForMainQueue()
//
//        verify(mockProvider).retrieveTransactionInfo(transactionHash: transactionHash)
//        verify(mockDelegate).didReceive(transactionRecord: equal(to: transactionRecord))
//
//        verifyNoMoreInteractions(mockProvider)
//        verifyNoMoreInteractions(mockDelegate)
//    }
//
//    func testRetrieveNil() {
//        stub(mockProvider) { mock in
//            when(mock.retrieveTransactionInfo(transactionHash: any())).thenReturn(Single.just(nil))
//        }
//
//        interactor.updateProvider(for: coin)
//
//        interactor.retrieveTransactionInfo(transactionHash: transactionHash)
//        waitForMainQueue()
//
//        verify(mockDelegate).onError(providerName: equal(to: providerName))
//        verifyNoMoreInteractions(mockDelegate)
//    }
//
//    func testRetrieveError() {
//        enum TestError: Error { case error }
//        let error = TestError.error
//
//        interactor.updateProvider(for: coin)
//
//        stub(mockProvider) { mock in
//            when(mock.retrieveTransactionInfo(transactionHash: any())).thenReturn(Single.error(error))
//        }
//
//        interactor.retrieveTransactionInfo(transactionHash: transactionHash)
//        waitForMainQueue()
//
//        verify(mockDelegate).onError(providerName: equal(to: providerName))
//        verifyNoMoreInteractions(mockDelegate)
//    }
//
//    func testCopyToPasteboard() {
//        let value = "test_value"
//
//        interactor.updateProvider(for: coin)
//
//        interactor.copyToPasteboard(value: value)
//        verify(mockPasteboardManager).set(value: value)
//    }
//
//    func testUrlForHash() {
//        interactor.updateProvider(for: coin)
//
//        let url = interactor.url(for: transactionHash)
//        XCTAssertEqual(url, "test_url")
//    }
//}
