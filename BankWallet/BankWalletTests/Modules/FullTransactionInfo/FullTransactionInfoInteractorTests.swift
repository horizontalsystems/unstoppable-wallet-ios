import XCTest
import Cuckoo
@testable import Bank_Dev_T

class FullTransactionInfoInteractorTests: XCTestCase {
    private var mockProvider: MockIFullTransactionInfoProvider!
    private var mockDelegate: MockIFullTransactionInfoInteractorDelegate!

    private var interactor: FullTransactionInfoInteractor!
    private var transactionHash: String!

    private var transactionRecord: FullTransactionRecord!

    override func setUp() {
        super.setUp()

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

        mockProvider = MockIFullTransactionInfoProvider()
        stub(mockProvider) { mock in
            when(mock.retrieveTransactionInfo(transactionHash: any())).thenDoNothing()
            when(mock.delegate.set(any())).thenDoNothing()
        }
        mockDelegate = MockIFullTransactionInfoInteractorDelegate()
        stub(mockDelegate) { mock in
            when(mock.didReceive(transactionRecord: any())).thenDoNothing()
        }

        interactor = FullTransactionInfoInteractor(transactionProvider: mockProvider)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        transactionHash = nil
        transactionRecord = nil

        mockProvider = nil

        interactor = nil

        super.tearDown()
    }

    func testRetrieve() {
        interactor.retrieveTransactionInfo(transactionHash: transactionHash)

        verify(mockProvider).retrieveTransactionInfo(transactionHash: transactionHash)
    }

    func testDidReceive() {
        interactor.didReceiveTransactionInfo(record: transactionRecord)

        verify(mockDelegate).didReceive(transactionRecord: equal(to: transactionRecord))
    }

}
