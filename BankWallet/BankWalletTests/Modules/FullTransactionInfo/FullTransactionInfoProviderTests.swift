import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

enum TestError: Int, Error { case error = 1 }

class FullTransactionInfoProviderTests: XCTestCase {
    private var mockDelegate: MockIFullTransactionInfoProviderDelegate!
    private var mockApiManager: MockIJSONApiManager!
    private var mockFullTransactionHelper: MockIFullTransactionHelper!

    private var provider: FullTransactionProvider!
    private var transactionHash: String!

    private var transactionRecord: FullTransactionRecord!

    override func setUp() {
        super.setUp()

        let path = "test_url_path"
        transactionHash = "test_hash"
        transactionRecord = FullTransactionRecord(resource: "test_record", url: "test_url", sections: [
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

        mockDelegate = MockIFullTransactionInfoProviderDelegate()
        stub(mockDelegate) { mock in
            when(mock.didReceiveTransactionInfo(record: any())).thenDoNothing()
            when(mock.didReceiveError(error: any())).thenDoNothing()
        }
        mockApiManager = MockIJSONApiManager()
        stub(mockApiManager) { mock in
            when(mock.getJSON(path: any(), parameters: any())).thenReturn(Observable.just([:]))
        }
        mockFullTransactionHelper = MockIFullTransactionHelper()
        stub(mockFullTransactionHelper) { mock in
            when(mock.map(json: any())).thenReturn(transactionRecord)
            when(mock.path.get).thenReturn(path)
        }
        provider = FullTransactionProvider(apiManager: mockApiManager, path: path, transactionHelper: mockFullTransactionHelper, async: false)
        provider.delegate = mockDelegate
    }

    override func tearDown() {
        transactionHash = nil
        transactionRecord = nil

        mockDelegate = nil
        mockApiManager = nil
        mockFullTransactionHelper = nil

        provider = nil

        super.tearDown()
    }

    func testRetrieveTransactionInfo() {
        provider.retrieveTransactionInfo(transactionHash: transactionHash)
        waitForMainQueue()

        verify(mockDelegate).didReceiveTransactionInfo(record: equal(to: transactionRecord))
    }

    func testError() {
        let error = TestError.error
        stub(mockApiManager) { mock in
            when(mock.getJSON(path: any(), parameters: any())).thenReturn(Observable.error(error))
        }
        provider.retrieveTransactionInfo(transactionHash: transactionHash)
        waitForMainQueue()

        verify(mockDelegate).didReceiveError(error: any())
        verifyNoMoreInteractions(mockDelegate)
    }

}
