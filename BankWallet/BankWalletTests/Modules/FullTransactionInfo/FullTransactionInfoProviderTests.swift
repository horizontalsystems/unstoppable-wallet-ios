import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

enum TestError: Int, Error { case error = 1 }

class FullTransactionInfoProviderTests: XCTestCase {
    private var mockApiManager: MockIJSONApiManager!
    private var mockAdapter: MockIFullTransactionInfoAdapter!

    private var provider: FullTransactionProvider!
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

        mockApiManager = MockIJSONApiManager()
        stub(mockApiManager) { mock in
            when(mock.getJSON(url: any(), parameters: any())).thenReturn(Observable.just([:]))
        }
        mockAdapter = MockIFullTransactionInfoAdapter()
        stub(mockAdapter) { mock in
            when(mock.convert(json: any())).thenReturn(transactionRecord)
        }

        provider = FullTransactionProvider(apiManager: mockApiManager, adapter: mockAdapter, providerName: "test_provider", apiUrl: "test_api", url: "test_url", async: false)
    }

    override func tearDown() {
        transactionHash = nil
        transactionRecord = nil

        mockApiManager = nil

        provider = nil

        super.tearDown()
    }

    func testRetrieveTransactionInfo() {
        let _ = provider.retrieveTransactionInfo(transactionHash: transactionHash)

        verify(mockApiManager).getJSON(url: equal(to: "test_url_path" + transactionHash), parameters: any())
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

}
