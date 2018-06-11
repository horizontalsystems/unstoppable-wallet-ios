import XCTest
import Cuckoo
@testable import Wallet

class RestorePresenterTests: XCTestCase {

    private var mockDelegate: MockRestorePresenterDelegate!
    private var mockRouter: MockRestoreRouterProtocol!
    private var mockView: MockRestoreViewProtocol!
    private var presenter: RestorePresenter!

    private let words = ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]

    override func setUp() {
        super.setUp()

        mockDelegate = MockRestorePresenterDelegate()
        mockRouter = MockRestoreRouterProtocol()
        mockView = MockRestoreViewProtocol()
        presenter = RestorePresenter(delegate: mockDelegate, router: mockRouter)

        presenter.view = mockView

        stub(mockDelegate) { mock in
            when(mock.restoreWallet(withWords: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.navigateToMain()).thenDoNothing()
            when(mock.close()).thenDoNothing()
        }
        stub(mockView) { mock in
            when(mock.showWordsValidationFailure()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockDelegate = nil
        mockRouter = nil
        mockView = nil
        presenter = nil

        super.tearDown()
    }

    func testDelegatesRestoreWallet() {
        presenter.restoreDidTap(withWords: words)

        verify(mockDelegate).restoreWallet(withWords: equal(to: words))
    }

    func testCloseOnCancel() {
        presenter.cancelDidTap()

        verify(mockRouter).close()
    }

    func testDidFailToRestore() {
        presenter.didFailToRestore()

        verify(mockView).showWordsValidationFailure()
    }

    func testDidRestore() {
        presenter.didRestoreWallet()

        verify(mockRouter).navigateToMain()
    }

}
