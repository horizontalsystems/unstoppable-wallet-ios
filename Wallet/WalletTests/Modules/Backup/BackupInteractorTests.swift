import XCTest
import Cuckoo
@testable import Wallet

class BackupInteractorTests: XCTestCase {

    private var mockPresenter: MockBackupPresenterProtocol!
    private var mockWordsProvider: MockBackupWordsProviderProtocol!
    private var mockIndexesProvider: MockBackupRandomIndexesProviderProtocol!
    private var interactor: BackupInteractor!

    private let words = ["burden", "swap", "fabric", "book", "palm", "main", "salute", "raw", "core", "reflect", "parade", "tone"]
    private let indexes = [2, 11]

    override func setUp() {
        super.setUp()

        mockPresenter = MockBackupPresenterProtocol()
        mockWordsProvider = MockBackupWordsProviderProtocol()
        mockIndexesProvider = MockBackupRandomIndexesProviderProtocol()
        interactor = BackupInteractor(wordsProvider: mockWordsProvider, indexesProvider: mockIndexesProvider)

        interactor.presenter = mockPresenter

        stub(mockWordsProvider) { mock in
            when(mock.getWords()).thenReturn(words)
        }
        stub(mockIndexesProvider) { mock in
            when(mock.getRandomIndexes(count: 2)).thenReturn(indexes)
        }
        stub(mockPresenter) { mock in
            when(mock.didFetch(words: any())).thenDoNothing()
            when(mock.didFetch(confirmationIndexes: any())).thenDoNothing()
            when(mock.didValidateSuccess()).thenDoNothing()
            when(mock.didValidateFailure()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockPresenter = nil
        mockWordsProvider = nil
        mockIndexesProvider = nil
        interactor = nil

        super.tearDown()
    }

    func testFetchWords() {
        interactor.fetchWords()

        verify(mockPresenter).didFetch(words: equal(to: words))
    }

    func testFetchConfirmationIndexes() {
        interactor.fetchConfirmationIndexes()

        verify(mockPresenter).didFetch(confirmationIndexes: equal(to: indexes))
    }

    func testValidateSuccess() {
        interactor.validate(confirmationWords: [3: "fabric", 12: "tone"])

        verify(mockPresenter).didValidateSuccess()
        verifyNoMoreInteractions(mockPresenter)
    }

    func testValidateFailureByOrder() {
        interactor.validate(confirmationWords: [1: "fabric", 12: "tone"])

        verify(mockPresenter).didValidateFailure()
        verifyNoMoreInteractions(mockPresenter)
    }

    func testValidateFailureByName() {
        interactor.validate(confirmationWords: [3: "fabric2", 12: "tone"])

        verify(mockPresenter).didValidateFailure()
        verifyNoMoreInteractions(mockPresenter)
    }

}
