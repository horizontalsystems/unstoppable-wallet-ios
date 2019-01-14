import XCTest
import Cuckoo
@testable import Bank_Dev_T

class FullTransactionInfoPresenterTests: XCTestCase {
    private var mockView: MockIFullTransactionInfoView!
    private var mockInteractor: MockIFullTransactionInfoInteractor!
    private var mockRouter: MockIFullTransactionInfoRouter!
    private var mockState: MockIFullTransactionInfoState!

    private var presenter: FullTransactionInfoPresenter!
    private var transactionHash: String!
    private var providerName: String!
    private var fullUrl: String!
    private var transactionRecord: FullTransactionRecord!

    override func setUp() {
        super.setUp()

        providerName = "test_provider"
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

        mockView = MockIFullTransactionInfoView()
        stub(mockView) { mock in
            when(mock.showLoading()).thenDoNothing()
            when(mock.hideLoading()).thenDoNothing()
            when(mock.showError(providerName: any())).thenDoNothing()
            when(mock.hideError()).thenDoNothing()
            when(mock.reload()).thenDoNothing()
            when(mock.showCopied()).thenDoNothing()
        }
        mockRouter = MockIFullTransactionInfoRouter()
        stub(mockRouter) { mock in
            when(mock.open(url: any())).thenDoNothing()
            when(mock.share(value: any())).thenDoNothing()
            when(mock.close()).thenDoNothing()
        }
        fullUrl = "test_url_with_hash"
        mockInteractor = MockIFullTransactionInfoInteractor()
        stub(mockInteractor) { mock in
            when(mock.retrieveTransactionInfo(transactionHash: any())).thenDoNothing()
            when(mock.onTap(item: any())).thenDoNothing()
            when(mock.retryLoadInfo()).thenDoNothing()
            when(mock.url(for: any())).thenReturn(fullUrl)
        }
        transactionHash = "test_hash"
        mockState = MockIFullTransactionInfoState()
        stub(mockState) { mock in
            when(mock.transactionHash.get).thenReturn(transactionHash)
            when(mock.transactionRecord.get).thenReturn(transactionRecord)
            when(mock.set(transactionRecord: any())).thenDoNothing()
        }
        presenter = FullTransactionInfoPresenter(interactor: mockInteractor, router: mockRouter, state: mockState)
        presenter.view = mockView
    }

    override func tearDown() {
        transactionRecord = nil
        fullUrl = nil
        providerName = nil

        mockRouter = nil
        mockInteractor = nil
        mockView = nil
        mockState = nil

        presenter = nil

        super.tearDown()
    }

    func testDidLoad() {
        presenter.viewDidLoad()

        verify(mockView).showLoading()
        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)
    }

    func testDidReceiveTransactionRecord() {
        presenter.didReceive(transactionRecord: transactionRecord)
        verify(mockState).set(transactionRecord: equal(to: transactionRecord))
        verify(mockView).hideLoading()
        verify(mockView).reload()
    }

    func testOnTap() {
        let item = transactionRecord.sections[0].items[0]
        presenter.onTap(item: item)

        verify(mockInteractor).onTap(item: equal(to: item))
    }

    func testOnTapResourceCell() {
        presenter.onTapResourceCell()

        verify(mockRouter).open(url: equal(to: fullUrl))
    }

    func testCopied() {
        presenter.onCopied()

        verify(mockView).showCopied()
    }

    func testOpenUrl() {
        let url = "test_url"
        presenter.onOpen(url: url)

        verify(mockRouter).open(url: equal(to: url))
    }
    
    func testClose() {
        presenter.onClose()
        
        verify(mockView).hideLoading()
        verify(mockRouter).close()
    }

    func testShowError() {
        presenter.onError(providerName: providerName)

        verify(mockView).hideLoading()
        verify(mockView).showError(providerName: equal(to: providerName))
    }

    func testOnConnectionRestored() {
        stub(mockState) { mock in
            when(mock.transactionHash.get).thenReturn(transactionHash)
            when(mock.transactionRecord.get).thenReturn(nil)
            when(mock.set(transactionRecord: any())).thenDoNothing()
        }

        presenter.retryLoadInfo()

        verify(mockView).hideError()
        verify(mockView).showLoading()
        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)

        verifyNoMoreInteractions(mockView)
        verifyNoMoreInteractions(mockInteractor)
    }

    func testOnConnectionRestoredExistData() {
        presenter.retryLoadInfo()

        verifyNoMoreInteractions(mockView)
        verifyNoMoreInteractions(mockInteractor)
    }

    func testOnRetryLoad() {
        presenter.onRetryLoad()

        verify(mockInteractor).retryLoadInfo()
    }

    func testRetryLoadInfo() {
        stub(mockState) { mock in
            when(mock.transactionRecord.get).thenReturn(nil)
        }
        presenter.retryLoadInfo()

        verify(mockView).hideError()
        verify(mockView).showLoading()
        verify(mockInteractor).retrieveTransactionInfo(transactionHash: transactionHash)

        verifyNoMoreInteractions(mockView)
        verifyNoMoreInteractions(mockInteractor)
    }

    func testOnShare() {
        presenter.onShare()

        verify(mockRouter).share(value: fullUrl)
    }

}
