import XCTest
import Cuckoo
@testable import Wallet

class BackupWalletPresenterTests: XCTestCase {

    private var mockRouter: MockBackupWalletRouterProtocol!
    private var mockDelegate: MockBackupWalletPresenterDelegate!
    private var mockView: MockBackupWalletViewProtocol!
    private var presenter: BackupWalletPresenter!

    private let words = ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]
    private let indexes = [2, 11]

    override func setUp() {
        super.setUp()

        mockRouter = MockBackupWalletRouterProtocol()
        mockDelegate = MockBackupWalletPresenterDelegate()
        mockView = MockBackupWalletViewProtocol()
        presenter = BackupWalletPresenter(delegate: mockDelegate, router: mockRouter)

        presenter.view = mockView

        stub(mockRouter) { mock in
            when(mock.close()).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.fetchWords()).thenDoNothing()
            when(mock.fetchConfirmationIndexes()).thenDoNothing()
            when(mock.validate(confirmationWords: any())).thenDoNothing()
        }
        stub(mockView) { mock in
            when(mock.show(words: any())).thenDoNothing()
            when(mock.showConfirmation(withIndexes: any())).thenDoNothing()
            when(mock.hideWords()).thenDoNothing()
            when(mock.hideConfirmation()).thenDoNothing()
            when(mock.showValidationFailure()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRouter = nil
        mockDelegate = nil
        mockView = nil
        presenter = nil

        super.tearDown()
    }

    func testDidFetchWords() {
        presenter.didFetch(words: words)
        verify(mockView).show(words: equal(to: words))
    }

    func testDidFetchConfirmationIndexes() {
        presenter.didFetch(confirmationIndexes: indexes)
        verify(mockView).showConfirmation(withIndexes: equal(to: indexes))
    }

    func testDidValidateSuccess() {
        presenter.didValidateSuccess()
        verify(mockRouter).close()
    }

    func testDidValidateFailure() {
        presenter.didValidateFailure()
        verify(mockView).showValidationFailure()
    }

    func testCancelDidTap() {
        presenter.cancelDidTap()
        verify(mockRouter).close()
    }

    func testShowWordsDidTap() {
        presenter.showWordsDidTap()
        verify(mockDelegate).fetchWords()
    }

    func testHideWordsDidTap() {
        presenter.hideWordsDidTap()
        verify(mockView).hideWords()
    }

    func testShowConfirmationDidTap() {
        presenter.showConfirmationDidTap()
        verify(mockDelegate).fetchConfirmationIndexes()
    }

    func testHideConfirmationDidTap() {
        presenter.hideConfirmationDidTap()
        verify(mockView).hideConfirmation()
    }

    func testValidateDidTap() {
        let confirmationWords = [1: "hello"]
        presenter.validateDidTap(confirmationWords: confirmationWords)
        verify(mockDelegate).validate(confirmationWords: equal(to: confirmationWords))
    }

}
