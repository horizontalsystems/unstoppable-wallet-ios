import XCTest
import Cuckoo
@testable import Wallet

class CreateWalletInteractorTests: XCTestCase {

    private var mockPresenter: MockCreateWalletPresenterProtocol!
    private var mockDataProvider: MockCreateWalletDataProviderProtocol!
    private var interactor: CreateWalletInteractor!

    override func setUp() {
        super.setUp()

        mockPresenter = MockCreateWalletPresenterProtocol()
        mockDataProvider = MockCreateWalletDataProviderProtocol()
        interactor = CreateWalletInteractor(presenter: mockPresenter, dataProvider: mockDataProvider)
    }

    override func tearDown() {
        mockPresenter = nil
        mockDataProvider = nil
        interactor = nil

        super.tearDown()
    }

    func testShowsWordsOnLoad() {
        let words = ["hello", "world"]

        stub(mockDataProvider) { mock in
            when(mock.generateWords()).thenReturn(words)
        }
        stub(mockPresenter) { mock in
            when(mock.show(words: any())).thenDoNothing()
        }

        interactor.viewDidLoad()

        verify(mockPresenter).show(words: equal(to: words))
    }

    func testShowsErrorIfFailedToGetWords() {
        stub(mockDataProvider) { mock in
            when(mock.generateWords()).thenReturn(nil)
        }
        stub(mockPresenter) { mock in
            when(mock.showError()).thenDoNothing()
        }

        interactor.viewDidLoad()

        verify(mockPresenter).showError()
    }

}
