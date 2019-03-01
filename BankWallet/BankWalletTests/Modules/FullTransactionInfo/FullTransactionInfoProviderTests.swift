import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

class FullTransactionInfoProviderTests: XCTestCase {
    private var mockApiManager: MockIJSONApiManager!
    private var mockAdapter: MockIFullTransactionInfoAdapter!
    private var mockProvider: MockIProvider!

    private var provider: FullTransactionInfoProvider!
    private var transactionHash: String!
    private var url: String!
    private var apiUrl: String!

    private var transactionRecord: FullTransactionRecord!

    override func setUp() {
        super.setUp()

        url = "test_url"
        transactionHash = "test_hash"
        apiUrl = "test_url_" + transactionHash
        let providerName = "test_provider"
        transactionRecord = FullTransactionRecord(providerName: providerName, sections: [
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

        mockApiManager = MockIJSONApiManager()
        stub(mockApiManager) { mock in
            when(mock.getJSON(url: any(), parameters: any())).thenReturn(Observable.just([:]))
        }
        mockAdapter = MockIFullTransactionInfoAdapter()
        stub(mockAdapter) { mock in
            when(mock.convert(json: any())).thenReturn(transactionRecord)
        }
        mockProvider = MockIProvider()
        stub(mockProvider) { mock in
            when(mock.name.get).thenReturn(providerName)
            when(mock.url(for: any())).thenReturn(url)
            when(mock.apiUrl(for: any())).thenReturn(apiUrl)
        }
        provider = FullTransactionInfoProvider(apiManager: mockApiManager, adapter: mockAdapter, provider: mockProvider, async: false)
    }

    override func tearDown() {
        url = nil
        apiUrl = nil
        transactionHash = nil
        transactionRecord = nil

        mockApiManager = nil
        mockProvider = nil

        provider = nil

        super.tearDown()
    }

    func testRetrieveTransactionInfo() {
        let _ = provider.retrieveTransactionInfo(transactionHash: transactionHash)

        verify(mockApiManager).getJSON(url: equal(to: apiUrl), parameters: any())
    }

    func testRetrieveMapping() {
        let jsonObservable = PublishSubject<[String: Any]>()
        stub(mockApiManager) { mock in
            when(mock.getJSON(url: any(), parameters: any())).thenReturn(jsonObservable)
        }

        let observable = provider.retrieveTransactionInfo(transactionHash: transactionHash)
        _ = observable.subscribe()

        jsonObservable.onNext([:])
        waitForMainQueue()

        verify(mockAdapter).convert(json: any())
    }

    func testUrl() {
        let url = provider.url(for: transactionHash)

        verify(mockProvider).url(for: transactionHash)
        XCTAssertEqual(url, self.url)
    }

}
