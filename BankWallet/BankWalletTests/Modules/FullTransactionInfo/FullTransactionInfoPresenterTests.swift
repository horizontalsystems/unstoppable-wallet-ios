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
    private var transactionRecord: FullTransactionRecord!

    override func setUp() {
        super.setUp()

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

        mockView = MockIFullTransactionInfoView()
        stub(mockView) { mock in
            when(mock.showLoading()).thenDoNothing()
            when(mock.hideLoading()).thenDoNothing()
            when(mock.reload()).thenDoNothing()
            when(mock.showCopied()).thenDoNothing()
        }
        mockRouter = MockIFullTransactionInfoRouter()
        stub(mockRouter) { mock in
            when(mock.open(url: any())).thenDoNothing()
        }
        mockInteractor = MockIFullTransactionInfoInteractor()
        stub(mockInteractor) { mock in
            when(mock.retrieveTransactionInfo(transactionHash: any())).thenDoNothing()
            when(mock.onTap(item: any())).thenDoNothing()
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

        verify(mockRouter).open(url: equal(to: "test_url" + transactionHash))
    }

    func onCopied() {
        presenter.onCopied()

        verify(mockView).showCopied()
    }

    func onOpenUrl() {
        let url = "test_url"
        presenter.onOpen(url: url)

        verify(mockRouter).open(url: equal(to: url))
    }
}
