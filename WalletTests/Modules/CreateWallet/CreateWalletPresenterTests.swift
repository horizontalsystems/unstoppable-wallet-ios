import XCTest
import Cuckoo
@testable import Wallet

class CreateWalletPresenterTests: XCTestCase {

    private var mockView: MockCreateWalletViewProtocol!
    private var presenter: CreateWalletPresenter!

    override func setUp() {
        super.setUp()

        mockView = MockCreateWalletViewProtocol()
        presenter = CreateWalletPresenter()

        presenter.view = mockView
    }

    override func tearDown() {
        mockView = nil
        presenter = nil

        super.tearDown()
    }

    func testShowsWords() {
        let words = ["hello", "world"]
        let wordsString = "hello world"

        stub(mockView) { mock in
            when(mock.show(wordsString: anyString())).thenDoNothing()
        }

        presenter.show(words: words)

        verify(mockView).show(wordsString: equal(to: wordsString))
    }

}
