import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

class FullTransactionInfoInteractorTests: XCTestCase {
    private var mockProvider: MockIFullTransactionInfoProvider!
    private var mockDelegate: MockIFullTransactionInfoInteractorDelegate!
    private var mockPasteboardManager: MockIPasteboardManager!

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
            when(mock.retrieveTransactionInfo(transactionHash: any())).thenReturn(Observable.just(transactionRecord))
        }
        mockDelegate = MockIFullTransactionInfoInteractorDelegate()
        stub(mockDelegate) { mock in
            when(mock.didReceive(transactionRecord: any())).thenDoNothing()
            when(mock.onError()).thenDoNothing()
            when(mock.onCopied()).thenDoNothing()
            when(mock.onOpen(url: any())).thenDoNothing()
        }
        mockPasteboardManager = MockIPasteboardManager()
        stub(mockPasteboardManager) { mock in
            when(mock.set(value: any())).thenDoNothing()
        }

        interactor = FullTransactionInfoInteractor(transactionProvider: mockProvider, pasteboardManager: mockPasteboardManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        transactionHash = nil
        transactionRecord = nil

        mockProvider = nil
        mockPasteboardManager = nil

        interactor = nil

        super.tearDown()
    }

    func testRetrieve() {
        interactor.retrieveTransactionInfo(transactionHash: transactionHash)
        waitForMainQueue()

        verify(mockProvider).retrieveTransactionInfo(transactionHash: transactionHash)
        verify(mockDelegate).didReceive(transactionRecord: equal(to: transactionRecord))

        verifyNoMoreInteractions(mockProvider)
        verifyNoMoreInteractions(mockDelegate)
    }

    func testRetrieveNil() {
        stub(mockProvider) { mock in
            when(mock.retrieveTransactionInfo(transactionHash: any())).thenReturn(Observable.just(nil))
        }

        interactor.retrieveTransactionInfo(transactionHash: transactionHash)
        waitForMainQueue()

        verify(mockDelegate).onError()
        verifyNoMoreInteractions(mockDelegate)
    }

    func testRetrieveError() {
        enum TestError: Error { case error }
        let error = TestError.error

        stub(mockProvider) { mock in
            when(mock.retrieveTransactionInfo(transactionHash: any())).thenReturn(Observable.error(error))
        }

        interactor.retrieveTransactionInfo(transactionHash: transactionHash)
        waitForMainQueue()

        verify(mockDelegate).onError()
        verifyNoMoreInteractions(mockDelegate)
    }

    func testTapNothing() {
        let value = "test_nothing"
        let item = FullTransactionItem(title: "test_item", value: value, clickable: false)
        interactor.onTap(item: item)

        verifyNoMoreInteractions(mockPasteboardManager)
        verifyNoMoreInteractions(mockDelegate)
    }

    func testTapCopy() {
        let value = "test_copy"
        let item = FullTransactionItem(title: "test_item", value: value, clickable: true)
        interactor.onTap(item: item)

        verify(mockPasteboardManager).set(value: equal(to: value))
        verify(mockDelegate).onCopied()

        verifyNoMoreInteractions(mockPasteboardManager)
        verifyNoMoreInteractions(mockDelegate)
    }

    func testTapOpenUrl() {
        let value = "test_url"
        let item = FullTransactionItem(title: "test_item", value: nil, clickable: true, url: value)
        interactor.onTap(item: item)

        verify(mockDelegate).onOpen(url: equal(to: value))

        verifyNoMoreInteractions(mockPasteboardManager)
        verifyNoMoreInteractions(mockDelegate)
    }

}
