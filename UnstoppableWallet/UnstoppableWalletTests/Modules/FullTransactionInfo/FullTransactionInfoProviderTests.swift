//import XCTest
//import Cuckoo
//import RxSwift
//@testable import Unstoppable_Dev_T
//
//class FullTransactionInfoProviderTests: XCTestCase {
//    private var mockApiManager: MockIJsonApiProvider!
//    private var mockAdapter: MockIFullTransactionInfoAdapter!
//    private var mockProvider: MockIProvider!
//
//    private var provider: FullTransactionInfoProvider!
//    private var transactionHash: String!
//    private var url: String!
//    private var requestObject: JsonApiProvider.RequestObject!
//
//    private var transactionRecord: FullTransactionRecord!
//
//    override func setUp() {
//        super.setUp()
//
//        url = "test_url"
//        transactionHash = "test_hash"
//        requestObject = JsonApiProvider.RequestObject.get(url: "test_url_" + transactionHash, params: nil)
//        let providerName = "test_provider"
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
//        mockApiManager = MockIJsonApiProvider()
//        stub(mockApiManager) { mock in
//            when(mock.getJson(requestObject: any())).thenReturn(Single.just([:]))
//        }
//        mockAdapter = MockIFullTransactionInfoAdapter()
//        stub(mockAdapter) { mock in
//            when(mock.convert(json: any())).thenReturn(transactionRecord)
//        }
//        mockProvider = MockIProvider()
//        stub(mockProvider) { mock in
//            when(mock.name.get).thenReturn(providerName)
//            when(mock.url(for: any())).thenReturn(url)
//            when(mock.requestObject(for: any())).thenReturn(requestObject)
//        }
//        provider = FullTransactionInfoProvider(apiProvider: mockApiManager, adapter: mockAdapter, provider: mockProvider, async: false)
//    }
//
//    override func tearDown() {
//        url = nil
//        requestObject = nil
//        transactionHash = nil
//        transactionRecord = nil
//
//        mockApiManager = nil
//        mockProvider = nil
//
//        provider = nil
//
//        super.tearDown()
//    }
//
//    func testRetrieveTransactionInfo() {
//        let _ = provider.retrieveTransactionInfo(transactionHash: transactionHash)
//
//        verify(mockApiManager).getJson(requestObject: equal(to: requestObject))
//    }
//
//    func testRetrieveMapping() {
//        let jsonSubject = PublishSubject<[String: Any]>()
//        stub(mockApiManager) { mock in
//            when(mock.getJson(requestObject: any())).thenReturn(jsonSubject.asSingle())
//        }
//
//        let single = provider.retrieveTransactionInfo(transactionHash: transactionHash)
//        _ = single.subscribe()
//
//        jsonSubject.onNext([:])
//        jsonSubject.onCompleted()
//
//        verify(mockAdapter).convert(json: any())
//    }
//
//    func testUrl() {
//        let url = provider.url(for: transactionHash)
//
//        verify(mockProvider).url(for: transactionHash)
//        XCTAssertEqual(url, self.url)
//    }
//
//}
